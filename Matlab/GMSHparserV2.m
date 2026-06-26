function [V,VE,SE,LE,PE,mapPhysNames,info] = GMSHparserV2(filename)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Extract entities contained in a single GMSH file in format v2.2 
%
%      Coded by Manuel A. Diaz @ Pprime | Univ-Poitiers, 2022.01.21
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Example call: GMSHparserV2('filename.msh')
%
% Output:
%     V: the vertices (nodes coordinates) -- (Nx3) array
%    VE: volumetric elements -- structure with fields .tet, .hex and .prism
%    SE: surface elements -- structure with fields .tri and .quad
%    LE: curvilinear elements (lines/edges) -- structure
%    PE: point elements (singular vertices) -- structure
%    mapPhysNames: maps phys.tag --> phys.name  -- map structure
%    info: version, format, endian test -- structure
%
% Note: This parser is designed to capture the following elements:
%
% Point:                Line:                   Triangle:
%
%        v                                              v
%        ^                                              ^
%        |                       v                      |
%        +----> u                ^                      2
%       0                        |                      |`\
%                                |                      |  `\
%                          0-----+-----1 --> u          |    `\
%                                                       |      `\
% Tetrahedron:                                          |        `\
%                                                       0----------1 --> u
%                   v
%                  ,
%                 /                    Based on the GMSH guide 4.9.4
%               2                      This are lower-order elements 
%             ,/|`\                    identified as:
%           ,/  |  `\                      E-1 : 2-node Line 
%         ,/    '.   `\                    E-2 : 3-node Triangle
%       ,/       |     `\                  E-3 : 4-node quadrilateral
%     ,/         |       `\                E-4 : 4-node tetrahedron
%    0-----------'.--------1 --> u         E-5 : 8-node hexahedron
%     `\.         |      ,/                E-6 : 6-node prism (wedge)
%        `\.      |    ,/                  E-15: 1-node point
%           `\.   '. ,/                Other elements can be added to 
%              `\. |/                  this parser by modifying the 
%                 `3                   Read Elements stage.
%                    `\.
%                       ` w            Happy coding ! M.D. 02/2022.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Read all sections

file = fileread(filename);

% Erase return-carrige character: (\r)
strFile = erase(file,char(13));

% Extract strings between:
MeshFormat    = extractBetween(strFile,['$MeshFormat',newline],[newline,'$EndMeshFormat']);
PhysicalNames = extractBetween(strFile,['$PhysicalNames',newline],[newline,'$EndPhysicalNames']);
Nodes         = extractBetween(strFile,['$Nodes',newline],[newline,'$EndNodes']);
Elements      = extractBetween(strFile,['$Elements',newline],[newline,'$EndElements']);

% Sanity check
if isempty(MeshFormat),    error('Error - Wrong File Format!'); end
if isempty(PhysicalNames), error('Error - No Physical names!'); end
if isempty(Nodes),         error('Error - Nodes are missing!'); end
if isempty(Elements),      error('Error - No elements found!'); end

% Split data lines into cells (Only in Matlab!)
cells_MF   = splitlines(MeshFormat);
cells_PN   = splitlines(PhysicalNames);
cells_N    = splitlines(Nodes);
cells_E    = splitlines(Elements);

% Get solver convention of names
[FEtype,BEtype] = load_convention();

%% Identify critical data within each section:

%********************%
% 1. Read Mesh Format
%********************%
line_data = sscanf(cells_MF{1},'%f %d %d');
info.version   = line_data(1);	% 2.2 is expected
info.file_type = line_data(2);	% 0:ASCII or 1:Binary
info.mode      = line_data(3);	% 1 in binary mode to detect endianness
fprintf('Mesh version %g, Binary %d, endian %d\n',...
            info.version,info.file_type,info.mode);

% Sanity check
if (info.version ~= 2.2), error('Error - Expected mesh format v2.2'); end
if (info.file_type ~= 0), error('Error - Binary file not allowed'); end

%***********************%
% 2. Read Physical Names
%***********************%
phys = struct('dim',{},'tag',{},'name',{});
numPhysicalNames = sscanf(cells_PN{1},'%d');
for n = 1:numPhysicalNames
   parts = strsplit(cells_PN{n+1});
   phys(n).dim  = str2double(parts{1});
   phys(n).tag  = str2double(parts{2});
   phys(n).name = strrep(parts{3},'"','');
end
mapPhysNames = containers.Map([phys.tag],{phys.name});
info.Dim = max([phys.dim]);

%***********************%
% 3. Read Nodes
%***********************%
l=1; % read first line
numNodes = sscanf(cells_N{l},'%d');

% allocate space for nodal data
V = zeros(numNodes,3); % [x,y,z] 

% Nodes Coordinates
for i=1:numNodes
    l = l+1; % update line counter
    line_data = sscanf(cells_N{l},'%d %g %g %g'); % [i,x(i),y(i),z(i)]
    V(i,:) = line_data(2:4);
end
fprintf('Total vertices found = %g\n',length(V));

%***********************%
% 4. Read Elements
%***********************%
l=1; % read first line
numElements = sscanf(cells_E{l},'%d');

% Line Format:
% elm-number elm-type number-of-tags < tag > ... node-number-list
elem = struct('EToV',[],'phys_tag',[],'geom_tag',[],'part_tag',[],'Etype',[]);
PE = elem;
LE = elem;
SE = struct('tri',elem,'quad',elem);
VE = struct('tet',elem,'hex',elem,'prism',elem);

% Element counters
numE1 = 0; % Lines Element counter
numE2 = 0; % Triangle Element counter
numE3 = 0; % Quadrilateral Element counter
numE4 = 0; % Tetrahedron Element counter
numE5 = 0; % Hexahedron Element counter
numE6 = 0; % Prism Element counter
numE15= 0; % point Element counter

% Read elements
for i = 1:numElements
    n = sscanf(cells_E{1+i}, '%d')';
    %elementID = n(1); % we use a local numbering instead
    elementType = n(2);
    numberOfTags = n(3);
    switch elementType
        case 1 % Line elements
            numE1 = numE1 + 1; % update element counter
            LE.Etype(numE1,1) = elementType;
            LE.EToV(numE1,:) = n(3+numberOfTags+1:end);
            if numberOfTags > 0 % get tags if they exist
                tags = n(3+(1:numberOfTags)); % get tags
                % tags(1) : physical entity to which the element belongs
                % tags(2) : elementary number to which the element belongs
                % tags(3) : number of partitions to which the element belongs
                % tags(4) : partition id number
                if length(tags) >= 1
                    LE.phys_tag(numE1,1) = tags(1);
                    if length(tags) >= 2
                        LE.geom_tag(numE1,1) = tags(2);
                        if length(tags) >= 4
                            LE.part_tag(numE1,1) = tags(4);
                        end
                    end
                end
            end
        case 2 % triangle elements
            numE2 = numE2 + 1; % update element counter
            SE.tri.Etype(numE2,1) = elementType;
            SE.tri.EToV(numE2,:) = n(3+numberOfTags+(1:3));
            if numberOfTags > 0 % get tags if they exist
                tags = n(3+(1:numberOfTags)); % get tags
                SE = assign_element_tags(SE,'tri',numE2,tags);
            end
        case 3 % quadrilateral elements
            numE3 = numE3 + 1; % update element counter
            SE.quad.Etype(numE3,1) = elementType;
            SE.quad.EToV(numE3,:) = n(3+numberOfTags+(1:4));
            if numberOfTags > 0 % get tags if they exist
                tags = n(3+(1:numberOfTags)); % get tags
                SE = assign_element_tags(SE,'quad',numE3,tags);
            end
        case 4 % tetrahedron elements
            numE4 = numE4 + 1; % update element counter
            VE.tet.Etype(numE4,1) = elementType;
            VE.tet.EToV(numE4,:) = n(3+numberOfTags+(1:4));
            if numberOfTags > 0 % get tags if they exist
                tags = n(3+(1:numberOfTags)); % get tags
                VE = assign_element_tags(VE,'tet',numE4,tags);
            end
        case 5 % hexahedron elements
            numE5 = numE5 + 1; % update element counter
            VE.hex.Etype(numE5,1) = elementType;
            VE.hex.EToV(numE5,:) = n(3+numberOfTags+(1:8));
            if numberOfTags > 0 % get tags if they exist
                tags = n(3+(1:numberOfTags)); % get tags
                VE = assign_element_tags(VE,'hex',numE5,tags);
            end
        case 6 % prism (wedge) elements
            numE6 = numE6 + 1; % update element counter
            VE.prism.Etype(numE6,1) = elementType;
            VE.prism.EToV(numE6,:) = n(3+numberOfTags+(1:6));
            if numberOfTags > 0 % get tags if they exist
                tags = n(3+(1:numberOfTags)); % get tags
                VE = assign_element_tags(VE,'prism',numE6,tags);
            end
        case 15 % point element
            numE15 = numE15 + 1; % update element counter
            PE.Etype(numE15,1) = elementType;
            PE.EToV(numE15,:) = n(3+numberOfTags+1:end);
            if numberOfTags > 0 % if they exist
                tags = n(3+(1:numberOfTags)); % get tags
                % tags(1) : physical entity to which the element belongs
                % tags(2) : elementary number to which the element belongs
                % tags(3) : number of partitions to which the element belongs
                % tags(4) : partition id number
                if length(tags) >= 1
                    PE.phys_tag(numE15,1) = tags(1);
                    if length(tags) >= 2
                        PE.geom_tag(numE15,1) = tags(2);
                        if length(tags) >= 4
                            PE.part_tag(numE15,1) = tags(4);
                        end
                    end
                end
            end
        otherwise, error('element not set yet!');
    end
end
%
% Find the total number of partitions
part_tags = [SE.tri.part_tag; SE.quad.part_tag; LE.part_tag; ...
             VE.tet.part_tag; VE.hex.part_tag; VE.prism.part_tag];
if isempty(part_tags)
    info.numPartitions = 1;
else
    info.numPartitions = max(part_tags);
end
%
fprintf('Total point-elements found = %g\n',numE15);
fprintf('Total line-elements found = %g\n',numE1);
fprintf('Total triangle-elements found = %g\n',numE2);
fprintf('Total quadrilateral-elements found = %g\n',numE3);
fprintf('Total tetrahedron-elements found = %g\n',numE4);
fprintf('Total hexahedron-elements found = %g\n',numE5);
fprintf('Total prism-elements found = %g\n',numE6);
% Sanity check
if numElements ~= (numE15+numE1+numE2+numE3+numE4+numE5+numE6)
    error('Total number of elements missmatch!'); 
end
%
end % GMSHv2 read function

function mesh = assign_element_tags(mesh,kind,idx,tags)
    % tags(1) : physical entity to which the element belongs
    % tags(2) : elementary number to which the element belongs
    % tags(3) : number of partitions to which the element belongs
    % tags(4) : partition id number
    if length(tags) >= 1
        mesh.(kind).phys_tag(idx,1) = tags(1);
        if length(tags) >= 2
            mesh.(kind).geom_tag(idx,1) = tags(2);
            if length(tags) >= 4
                mesh.(kind).part_tag(idx,1) = tags(4);
            end
        end
    end
end

function [DEtype,BEtype] = load_convention()
    % Define map of costum domain Elements types (Etype)
    DEnames = {'fluid','fluid1','fluid2','fluid3','fluid4',...
               'solid','solid1','solid2','solid3','solid4'};
    DEsolverIds = [0,1,2,3,4,5,6,7,8,9]; % costume IDs expected in our solver
    DEtype = containers.Map(DEnames,DEsolverIds);
    
    % Define map of costum Boundary Elements types (BEtype)
    BCnames = { 'BCfile','free','wall','outflow',...
            'imposedPressure','imposedVelocities',...
            'axisymmetric_y','axisymmetric_x',...
            'BC_rec','free_rec','wall_rec','outflow_rec',...
            'imposedPressure_rec','imposedVelocities_rec',...
            'axisymmetric_y_rec','axisymmetric_x_rec',...
            'piston_pressure','piston_velocity',...
            'recordingObject','recObj','piston_stress'};
    BCsolverIds = [0,1,2,3,4,5,6,7,10,11,12,13,14,15,16,17,18,19,20,20,21]; 
    BEtype = containers.Map(BCnames,BCsolverIds);
end