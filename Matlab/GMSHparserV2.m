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
%                 ,
%                /                Based on the GMSH guide 4.9.4
%              2                  This are lower-order & high-order 
%            ,/|`\                elements identified as families:
%          ,/  |  `\                 E-1, E-8, E-26 : 2, 3, 4-node Line 
%        ,/    '.   `\               E-2, E-9, E-21 : 3, 6, 10-node Triangle
%      ,/       |     `\             E-3, E-10, E-36: 4, 9, 16-node Quadrilateral
%    ,/         |       `\           E-4, E-11, E-29: 4, 10, 20-node Tetrahedron
%   0-----------'.--------1 --> u    E-5, E-12, E-92: 8, 27, 64-node Hexahedron
%    `\.         |      ,/           E-6, E-13: E-90: 6, 18, 40-node Prism (wedge)
%       `\.      |    ,/             E-15 : 1-node point
%          `\.   '. ,/            Other elements can be added to 
%             `\. |/              this parser by modifying the 
%                `3               Read Elements stage.
%                  `\.
%                     ` w        Happy coding ! M.D. 02/2022.
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
[FEtype,BEtype] = load_convention(); %#ok<ASGLU>

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
V_tags = zeros(numNodes,1); % node tags
V = zeros(numNodes,3); % [x,y,z] 

% Nodes Coordinates
for i=1:numNodes
    l = l+1; % update line counter
    line_data = sscanf(cells_N{l},'%d %g %g %g'); % [i,x(i),y(i),z(i)]    
    V_tags(i,1) = line_data(1);
    V(i,:) = line_data(2:4);
end
assert(V_tags(end) == numNodes, 'Node tags are not consecutive!');
fprintf('Total vertices found = %g\n',length(V));

%***********************%
% 4. Read Elements
%***********************%
l=1; % read first line
numElements = sscanf(cells_E{l},'%d');

% Line Format:
% elm-number elm-type number-of-tags < tag > ... node-number-list
elem = struct('EToV',[],'phys_tag',[],'geom_tag',[],'part_tag',[],'Etype',[]);
PE = struct('pnt',elem);
LE = struct('lin',elem);
SE = struct('tri',elem,'quad',elem);
VE = struct('tet',elem,'hex',elem,'prism',elem);

% Element counters
numE1 = 0; % 1st-order Lines Element counter
numE2 = 0; % 1st-order Triangle Element counter
numE3 = 0; % 1st-order Quadrilateral Element counter
numE4 = 0; % 1st-order Tetrahedron Element counter
numE5 = 0; % 1st-order Hexahedron Element counter
numE6 = 0; % 1st-order Prism Element counter

numE8 = 0; % 2nd-order Lines Element counter
numE9 = 0; % 2nd-order Triangle Element counter
numE10 = 0; % 2nd-order Quadrilateral Element counter
numE11 = 0; % 2nd-order Tetrahedron Element counter
numE12 = 0; % 2nd-order Hexahedron Element counter
numE13 = 0; % 2nd-order Prism Element counter

numE26 = 0; % 3rd-order Lines Element counter
numE21 = 0; % 3rd-order Triangle Element counter
numE36 = 0; % 3rd-order Quadrilateral Element counter
numE29 = 0; % 3rd-order Tetrahedron Element counter
numE92 = 0; % 3rd-order Hexahedron Element counter
numE90 = 0; % 3rd-order Prism Element counter

numE15= 0; % point Element counter

% Read elements
for i = 1:numElements
    n = sscanf(cells_E{1+i}, '%d')';
    %elementID = n(1); % we use a local numbering instead
    elementType = n(2);
    numberOfTags = n(3);
    switch elementType
        case 1 % 1st-order Line elements
            numE1 = numE1 + 1; % update element counter
            LE.lin.Etype(numE1,1) = elementType;
            LE.lin.EToV(numE1,:) = n(3+numberOfTags+1:end);
            if numberOfTags > 0 % get tags if they exist
                tags = n(3+(1:numberOfTags)); % get tags
                LE = assign_element_tags(LE,'lin',numE1,tags);
            end
        case 2 % 1st-order Triangle elements
            numE2 = numE2 + 1; % update element counter
            SE.tri.Etype(numE2,1) = elementType;
            SE.tri.EToV(numE2,:) = n(3+numberOfTags+1:end);
            if numberOfTags > 0 % get tags if they exist
                tags = n(3+(1:numberOfTags)); % get tags
                SE = assign_element_tags(SE,'tri',numE2,tags);
            end
        case 3 % 1st-order Quadrilateral elements
            numE3 = numE3 + 1; % update element counter
            SE.quad.Etype(numE3,1) = elementType;
            SE.quad.EToV(numE3,:) = n(3+numberOfTags+1:end);
            if numberOfTags > 0 % get tags if they exist
                tags = n(3+(1:numberOfTags)); % get tags
                SE = assign_element_tags(SE,'quad',numE3,tags);
            end
        case 4 % 1st-order Tetrahedron elements
            numE4 = numE4 + 1; % update element counter
            VE.tet.Etype(numE4,1) = elementType;
            VE.tet.EToV(numE4,:) = n(3+numberOfTags+1:end);
            if numberOfTags > 0 % get tags if they exist
                tags = n(3+(1:numberOfTags)); % get tags
                VE = assign_element_tags(VE,'tet',numE4,tags);
            end
        case 5 % 1st-order Hexahedron elements
            numE5 = numE5 + 1; % update element counter
            VE.hex.Etype(numE5,1) = elementType;
            VE.hex.EToV(numE5,:) = n(3+numberOfTags+1:end);
            if numberOfTags > 0 % get tags if they exist
                tags = n(3+(1:numberOfTags)); % get tags
                VE = assign_element_tags(VE,'hex',numE5,tags);
            end
        case 6 % 1st-order Prism (wedge) elements
            numE6 = numE6 + 1; % update element counter
            VE.prism.Etype(numE6,1) = elementType;
            VE.prism.EToV(numE6,:) = n(3+numberOfTags+1:end);
            if numberOfTags > 0 % get tags if they exist
                tags = n(3+(1:numberOfTags)); % get tags
                VE = assign_element_tags(VE,'prism',numE6,tags);
            end
        case 8 % 2nd-order Line elements
            numE8 = numE8 + 1; % update element counter
            LE.lin.Etype(numE8,1) = elementType;
            LE.lin.EToV(numE8,:) = n(3+numberOfTags+1:end);
            if numberOfTags > 0 % get tags if they exist
                tags = n(3+(1:numberOfTags)); % get tags
                LE = assign_element_tags(LE,'lin',numE8,tags);
            end
        case 9 % 2nd-order Triangle elements
            numE9 = numE9 + 1; % update element counter
            SE.tri.Etype(numE9,1) = elementType;
            SE.tri.EToV(numE9,:) = n(3+numberOfTags+1:end);
            if numberOfTags > 0 % get tags if they exist
                tags = n(3+(1:numberOfTags)); % get tags
                SE = assign_element_tags(SE,'tri',numE9,tags);
            end
        case 10 % 2nd-order Quadrilateral elements
            numE10 = numE10 + 1; % update element counter
            SE.quad.Etype(numE10,1) = elementType;
            SE.quad.EToV(numE10,:) = n(3+numberOfTags+1:end);
            if numberOfTags > 0 % get tags if they exist
                tags = n(3+(1:numberOfTags)); % get tags
                SE = assign_element_tags(SE,'quad',numE10,tags);
            end
        case 11 % 2nd-order Tetrahedron elements
            numE11 = numE11 + 1; % update element counter
            VE.tet.Etype(numE11,1) = elementType;
            VE.tet.EToV(numE11,:) = n(3+numberOfTags+1:end);
            if numberOfTags > 0 % get tags if they exist
                tags = n(3+(1:numberOfTags)); % get tags
                VE = assign_element_tags(VE,'tet',numE11,tags);
            end
        case 12 % 2nd-order Hexahedron elements
            numE12 = numE12 + 1; % update element counter
            VE.hex.Etype(numE12,1) = elementType;
            VE.hex.EToV(numE12,:) = n(3+numberOfTags+1:end);
            if numberOfTags > 0 % get tags if they exist
                tags = n(3+(1:numberOfTags)); % get tags
                VE = assign_element_tags(VE,'hex',numE12,tags);
            end
        case 13 % 2nd-order Prism (wedge) elements
            numE13 = numE13 + 1; % update element counter
            VE.prism.Etype(numE13,1) = elementType;
            VE.prism.EToV(numE13,:) = n(3+numberOfTags+1:end);
            if numberOfTags > 0 % get tags if they exist
                tags = n(3+(1:numberOfTags)); % get tags
                VE = assign_element_tags(VE,'prism',numE13,tags);
            end
        case 26 % 3rd-order Line elements
            numE26 = numE26 + 1; % update element counter
            LE.lin.Etype(numE26,1) = elementType;
            LE.lin.EToV(numE26,:) = n(3+numberOfTags+1:end);
            if numberOfTags > 0 % get tags if they exist
                tags = n(3+(1:numberOfTags)); % get tags
                LE = assign_element_tags(LE,'lin',numE26,tags);
            end
        case 21 % 3rd-order Triangle elements
            numE21 = numE21 + 1; % update element counter
            SE.tri.Etype(numE21,1) = elementType;
            SE.tri.EToV(numE21,:) = n(3+numberOfTags+1:end);
            if numberOfTags > 0 % get tags if they exist
                tags = n(3+(1:numberOfTags)); % get tags
                SE = assign_element_tags(SE,'tri',numE21,tags);
            end
        case 36 % 3rd-order Quadrilateral elements
            numE36 = numE36 + 1; % update element counter
            SE.quad.Etype(numE36,1) = elementType;
            SE.quad.EToV(numE36,:) = n(3+numberOfTags+1:end);
            if numberOfTags > 0 % get tags if they exist
                tags = n(3+(1:numberOfTags)); % get tags
                SE = assign_element_tags(SE,'quad',numE36,tags);
            end
        case 29 % 3rd-order Tetrahedron elements
            numE29 = numE29 + 1; % update element counter
            VE.tet.Etype(numE29,1) = elementType;
            VE.tet.EToV(numE29,:) = n(3+numberOfTags+1:end);
            if numberOfTags > 0 % get tags if they exist
                tags = n(3+(1:numberOfTags)); % get tags
                VE = assign_element_tags(VE,'tet',numE29,tags);
            end
        case 92 % 3rd-order Hexahedron elements
            numE92 = numE92 + 1; % update element counter
            VE.hex.Etype(numE92,1) = elementType;
            VE.hex.EToV(numE92,:) = n(3+numberOfTags+1:end);
            if numberOfTags > 0 % get tags if they exist
                tags = n(3+(1:numberOfTags)); % get tags
                VE = assign_element_tags(VE,'hex',numE92,tags);
            end
        case 90 % 3rd-order Prism (wedge) elements
            numE90 = numE90 + 1; % update element counter
            VE.prism.Etype(numE90,1) = elementType;
            VE.prism.EToV(numE90,:) = n(3+numberOfTags+1:end);
            if numberOfTags > 0 % get tags if they exist
                tags = n(3+(1:numberOfTags)); % get tags
                VE = assign_element_tags(VE,'prism',numE90,tags);
            end
        case 15 % Point element
            numE15 = numE15 + 1; % update element counter
            PE.pnt.Etype(numE15,1) = elementType;
            PE.pnt.EToV(numE15,:) = n(3+numberOfTags+1:end);
            if numberOfTags > 0 % if they exist
                tags = n(3+(1:numberOfTags)); % get tags
                PE = assign_element_tags(PE,'pnt',numE15,tags);
            end
        otherwise, error('ERROR: element type not in list');
    end
end
%
% Find the total number of partitions
part_tags = [SE.tri.part_tag; SE.quad.part_tag; LE.lin.part_tag; ...
             VE.tet.part_tag; VE.hex.part_tag; VE.prism.part_tag; ...
             PE.pnt.part_tag];
if isempty(part_tags)
    info.single_domain = true;
    info.numPartitions = 1;
else
    info.single_domain = false;
    info.numPartitions = max(part_tags);
end
%
% Total number of elements in each order
numElements1stOrder = numE1 + numE2 + numE3 + numE4 + numE5 + numE6;
numElements2ndOrder = numE8 + numE9 + numE10 + numE11 + numE12 + numE13;
numElements3rdOrder = numE26 + numE21 + numE36 + numE29 + numE90 + numE92;
% Gmsh treats element order as a global setting. Mesh is either 1st, 2nd or 3rd order
if numElements1stOrder ~= 0
    info.element_order = 1;
    fprintf('Total point-elements found = %d\n',numE15);
    fprintf('Total line-elements found = %d\n',numE1);
    fprintf('Total triangle-elements found = %d\n',numE2);
    fprintf('Total quadrilateral-elements found = %d\n',numE3);
    fprintf('Total tetrahedron-elements found = %d\n',numE4);
    fprintf('Total hexahedron-elements found = %d\n',numE5);
    fprintf('Total prism-elements found = %d\n',numE6);
    % Sanity check
    if numElements ~= numElements1stOrder + numE15
        error('Total number of elements missmatch!'); 
    end
elseif numElements2ndOrder ~= 0
    info.element_order = 2;
    fprintf('Total point-elements found = %d\n',numE15);
    fprintf('Total line-elements found = %d\n',numE8);
    fprintf('Total triangle-elements found = %d\n',numE9);
    fprintf('Total quadrilateral-elements found = %d\n',numE10);
    fprintf('Total tetrahedron-elements found = %d\n',numE11);
    fprintf('Total hexahedron-elements found = %d\n',numE12);
    fprintf('Total prism-elements found = %d\n',numE13);
    % Sanity check
    if numElements ~= numElements2ndOrder + numE15
        error('Total number of elements missmatch!'); 
    end
elseif numElements3rdOrder ~= 0 
    info.element_order = 3;
    fprintf('Total point-elements found = %d\n',numE15);
    fprintf('Total line-elements found = %d\n',numE26);
    fprintf('Total triangle-elements found = %d\n',numE21);
    fprintf('Total quadrilateral-elements found = %d\n',numE36);
    fprintf('Total tetrahedron-elements found = %d\n',numE29);
    fprintf('Total hexahedron-elements found = %d\n',numE92);
    fprintf('Total prism-elements found = %d\n',numE90);
    % Sanity check
    if numElements ~= numElements3rdOrder + numE15
        error('Total number of elements missmatch!'); 
    end
else 
    info.element_order = 0;
    fprintf('Total point-elements found = %d\n',numE15);
    % Sanity check
    if numElements ~= numE15
        error('Total number of elements missmatch!'); 
    end
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