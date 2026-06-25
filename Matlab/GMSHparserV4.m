function [V,VE,SE,LE,PE,mapPhysNames,info] = GMSHparserV4(filename)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Extract entities contained in a single GMSH file in format v4.1 
%
%      Coded by Manuel A. Diaz @ Pprime | Univ-Poitiers, 2022.01.21
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Example call: GMSHparserV4('filename.msh')
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
Entities      = extractBetween(strFile,['$Entities',newline],[newline,'$EndEntities']);
PartEntities  = extractBetween(strFile,['$PartitionedEntities',newline],[newline,'$EndPartitionedEntities']);
Nodes         = extractBetween(strFile,['$Nodes',newline],[newline,'$EndNodes']);
Elements      = extractBetween(strFile,['$Elements',newline],[newline,'$EndElements']);

% Sanity check
if isempty(MeshFormat),    error('Error - Wrong File Format!'); end
if isempty(PhysicalNames), error('Error - No Physical names!'); end
if isempty(Entities),      error('Error - No Entities found!'); end
if isempty(Nodes),         error('Error - Nodes are missing!'); end
if isempty(Elements),      error('Error - No elements found!'); end

% Is it a single or partitioned domain?
if isempty(PartEntities), single_domain=1; else, single_domain=0; end

% Split data lines into cells (Only in Matlab!)
cells_MF   = splitlines(MeshFormat);
cells_PN   = splitlines(PhysicalNames);
cells_Ent  = splitlines(Entities);
cells_N    = splitlines(Nodes);
cells_E    = splitlines(Elements);
if not(single_domain)
    cells_PEnt = splitlines(PartEntities);
end

% Get solver convention of names
[FEtype,BEtype] = load_convention();

%% Identify critical data within each section:

%********************%
% 1. Read Mesh Format
%********************%
line_data = sscanf(cells_MF{1},'%f %d %d');
info.version   = line_data(1);	% 4.1 is expected
info.file_type = line_data(2);	% 0:ASCII or 1:Binary
info.mode      = line_data(3);	% 1 in binary mode to detect endianness
fprintf('Mesh version %g, Binary %d, endian %d\n',...
            info.version,info.file_type,info.mode);

% Sanity check
if (info.version ~= 4.1), error('Error - Expected mesh format v4.1'); end
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

if single_domain
    %***********************%
    % 3. Read Entities
    %***********************%
    info.numPartitions = 1;
    l=1; % line counter
    line_data = sscanf(cells_Ent{l},'%d %d %d %d');
    nP = line_data(1);
    nC = line_data(2);
    nS = line_data(3);
    nV = line_data(4);
    l=2; % line counter
    points  = struct('ID',{},'Phys_ID',{});
    curves  = struct('ID',{},'Phys_ID',{});
    surfaces= struct('ID',{},'Phys_ID',{});
    volumes = struct('ID',{},'Phys_ID',{});
    % read points
    if nP>0
        for i = 1:nP
            points(i) = get_entity(cells_Ent{l},'node');
            l = l+1; % update line counter
        end
        point2Phys = containers.Map([points.ID],[points.Phys_ID]);
    end
    % read curves
    if nC>0
        for i = 1:nC
            curves(i) = get_entity(cells_Ent{l},'curve');
            l = l+1; % update line counter
        end
        curve2Phys = containers.Map([curves.ID],[curves.Phys_ID]);
    end
    % read surfaces
    if nS>0
        for i = 1:nS
            surfaces(i) = get_entity(cells_Ent{l},'surface');
            l = l+1; % update line counter
        end
        surf2Phys = containers.Map([surfaces.ID],[surfaces.Phys_ID]);
    end
    % read volumes
    if nV>0
        for i = 1:nV
            volumes(i) = get_entity(cells_Ent{l},'volume');
            l = l+1; % update line counter
        end
        volm2Phys = containers.Map([volumes.ID],[volumes.Phys_ID]);
    end

else
    %******************************%
    % 4. Read Partitioned Entities
    %******************************%
    l=1; info.numPartitions = sscanf(cells_PEnt{l},'%d');
    %l=2; numGhostEntities = sscanf(cells_PEnt{l},'%d'); % not needed
    l=3; line_data = sscanf(cells_PEnt{l},'%d');
    nP = line_data(1);
    nC = line_data(2);
    nS = line_data(3);
    nV = line_data(4);
    l=4; % line counter
    points  = struct('chld_ID',{},'Prnt_ID',{},'Part_ID',{},'Phys_ID',{});
    curves  = struct('chld_ID',{},'Prnt_ID',{},'Part_ID',{},'Phys_ID',{});
    surfaces= struct('chld_ID',{},'Prnt_ID',{},'Part_ID',{},'Phys_ID',{});
    volumes = struct('chld_ID',{},'Prnt_ID',{},'Part_ID',{},'Phys_ID',{});
    % read points
    if nP>0
        for i = 1:nP
            points(i) = get_partitionedEntity(cells_PEnt{l},'node');
            l = l+1; % update line counter
        end
        point2Part = containers.Map([points.chld_ID],{points.Part_ID});
        point2Phys = containers.Map([points.chld_ID],[points.Phys_ID]);
        point2Geom = containers.Map([points.chld_ID],[points.Prnt_ID]);
    end
    % read curves
    if nC>0
        for i = 1:nC
            curves(i) = get_partitionedEntity(cells_PEnt{l},'curve');
            l = l+1; % update line counter
        end
        curve2Part = containers.Map([curves.chld_ID],{curves.Part_ID});
        curve2Phys = containers.Map([curves.chld_ID],[curves.Phys_ID]);
        curve2Geom = containers.Map([curves.chld_ID],[curves.Prnt_ID]);
    end
    % read surfaces
    if nS>0
        for i = 1:nS
            surfaces(i) = get_partitionedEntity(cells_PEnt{l},'surface');
            l = l+1; % update line counter
        end
        surf2Part = containers.Map([surfaces.chld_ID],{surfaces.Part_ID});
        surf2Phys = containers.Map([surfaces.chld_ID],[surfaces.Phys_ID]);
        surf2Geom = containers.Map([surfaces.chld_ID],[surfaces.Prnt_ID]);
    end
    % read volumes
    if nV>0
        for i = 1:nV
            volumes(i) = get_partitionedEntity(cells_PEnt{l},'volume');
            l = l+1; % update line counter
        end
        volm2Part = containers.Map([volumes.chld_ID],{volumes.Part_ID});
        volm2Phys = containers.Map([volumes.chld_ID],[volumes.Phys_ID]);
        volm2Geom = containers.Map([volumes.chld_ID],[volumes.Prnt_ID]);
    end
end

%***********************%
% 5. Read Nodes
%***********************%
l=1; % read first line
line_data = sscanf(cells_N{l},'%d %d %d %d');
numEntityBlocks = line_data(1);
numNodes        = line_data(2);
%minNodeTag      = line_data(3); % not needed
%maxNodeTag      = line_data(4); % not needed
V = get_nodes(cells_N,numEntityBlocks,numNodes);
fprintf('Total vertices found = %g\n',length(V));

%***********************%
% 6. Read Elements
%***********************%
l=1; % read first line
line_data = sscanf(cells_E{l},'%d %d %d %d');
numEntityBlocks = line_data(1);
numElements     = line_data(2);
%minElementsTag  = line_data(3); % not needed
%maxElementsTag  = line_data(4); % not needed

% Allocate space for Elements data
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

% Read elements blocks
for ent = 1:numEntityBlocks
    l = l+1; % update line counter
    line_data = sscanf(cells_E{l},'%d %d %d %d');
    %entityDim = line_data(1); % 0:point, 1:curve, 2:surface, 3:volume
    entityTag = line_data(2); % this is: Entity.ID | Entity.child_ID
    elementType = line_data(3); % 1:line, 2:tri, 3:quad, 4:tet, 5:hex, 6:prism, 15:point
    numElementsInBlock = line_data(4);
    
    % Read Elements in block
    for i=1:numElementsInBlock
        l = l+1; % update line counter
        line_data = sscanf(cells_E{l},'%d %d %d %d');
        %elementID = line_data(1); % we use a local numbering instead
        switch elementType % <-- Should use entittyDim, but we only search 4 type of elements
            case 1 % Line elements
                numE1 = numE1 + 1; % update element counter
                LE.Etype(numE1,1) = elementType;
                LE.EToV(numE1,:) = line_data(2:3);
                LE.phys_tag(numE1,1) = curve2Phys(entityTag);
                if not(single_domain)
                    LE.geom_tag(numE1,1) = curve2Geom(entityTag);
                    LE.part_tag(numE1,1) = curve2Part(entityTag);
                else
                    LE.geom_tag(numE1,1) = entityTag;
                end
            case 2 % triangle elements
                numE2 = numE2 + 1; % update element counter
                SE.tri.Etype(numE2,1) = elementType;
                SE.tri.EToV(numE2,:) = line_data(2:4);
                SE.tri.phys_tag(numE2,1) = surf2Phys(entityTag);
                if not(single_domain)
                    SE.tri.geom_tag(numE2,1) = surf2Geom(entityTag);
                    SE.tri.part_tag(numE2,1) = surf2Part(entityTag);
                else
                    SE.tri.geom_tag(numE2,1) = entityTag;
                end
            case 3 % quadrilateral elements
                numE3 = numE3 + 1; % update element counter
                SE.quad.Etype(numE3,1) = elementType;
                SE.quad.EToV(numE3,:) = line_data(2:5);
                SE.quad.phys_tag(numE3,1) = surf2Phys(entityTag);
                if not(single_domain)
                    SE.quad.geom_tag(numE3,1) = surf2Geom(entityTag);
                    SE.quad.part_tag(numE3,1) = surf2Part(entityTag);
                else
                    SE.quad.geom_tag(numE3,1) = entityTag;
                end
            case 4 % tetrahedron elements
                numE4 = numE4 + 1; % update element counter
                VE.tet.Etype(numE4,1) = elementType;
                VE.tet.EToV(numE4,:) = line_data(2:5);
                VE.tet.phys_tag(numE4,1) = volm2Phys(entityTag);
                if not(single_domain)
                    VE.tet.geom_tag(numE4,1) = volm2Geom(entityTag);
                    VE.tet.part_tag(numE4,1) = volm2Part(entityTag);
                else 
                    VE.tet.geom_tag(numE4,1) = entityTag;
                end
            case 5 % hexahedron elements
                numE5 = numE5 + 1; % update element counter
                VE.hex.Etype(numE5,1) = elementType;
                VE.hex.EToV(numE5,:) = line_data(2:9);
                VE.hex.phys_tag(numE5,1) = volm2Phys(entityTag);
                if not(single_domain)
                    VE.hex.geom_tag(numE5,1) = volm2Geom(entityTag);
                    VE.hex.part_tag(numE5,1) = volm2Part(entityTag);
                else
                    VE.hex.geom_tag(numE5,1) = entityTag;
                end
            case 6 % prism (wedge) elements
                numE6 = numE6 + 1; % update element counter
                VE.prism.Etype(numE6,1) = elementType;
                VE.prism.EToV(numE6,:) = line_data(2:7);
                VE.prism.phys_tag(numE6,1) = volm2Phys(entityTag);
                if not(single_domain)
                    VE.prism.geom_tag(numE6,1) = volm2Geom(entityTag);
                    VE.prism.part_tag(numE6,1) = volm2Part(entityTag);
                else
                    VE.prism.geom_tag(numE6,1) = entityTag;
                end
            case 15 % Point elements
                numE15 = numE15 + 1; % update element counter
                PE.Etype(numE15,1) = elementType;
                PE.EToV(numE15,:) = line_data(2);
                PE.phys_tag(numE15,1) = point2Phys(entityTag);
                if not(single_domain)
                    PE.geom_tag(numE15,1) = point2Geom(entityTag);
                    PE.part_tag(numE15,1) = point2Part(entityTag);
                else
                    PE.geom_tag(numE15,1) = entityTag;
                end
            otherwise, error('ERROR: element type not in list');
        end
    end
end
%
fprintf('Total point-elements found = %d\n',numE15);
fprintf('Total line-elements found = %d\n',numE1);
fprintf('Total triangle-elements found = %d\n',numE2);
fprintf('Total quadrilateral-elements found = %d\n',numE3);
fprintf('Total tetrahedron-elements found = %d\n',numE4);
fprintf('Total hexahedron-elements found = %d\n',numE5);
fprintf('Total prism-elements found = %d\n',numE6);
% Sanity check
if numElements ~= (numE15+numE1+numE2+numE3+numE4+numE5+numE6)
    error('Total number of elements missmatch!'); 
end
%
end % GMSHv4 read function

% Get single entity information:
function entity = get_entity(str_line,type)
    
    vector = str2double(regexp(str_line,'-?[\d.]+(?:e-?\d+)?','match'));

    switch type
        case 'node'
            % 1. get entityTag
            entityTag = vector(1);

            % 3. get entity coordinates % not needed
            % ignore indexes 2, 3, 4

            % 3. get physical tag associated
            numPhysicalTags = vector(5);
            if numPhysicalTags == 0
                physicalTag = -1;
            else
                physicalTag = vector(6);
            end

        otherwise
            % 1. get entityTag
            entityTag = vector(1);
        
            % 2. get entity boxing limits (for visualization) % not needed
            % ignore indexes 2, 3, 4, 5, 6, 7
            
            % 3. get physical tag associated
            numPhysicalTags = vector(8);
            if numPhysicalTags == 0
                physicalTag = -1;
            else
                physicalTag = vector(9);
            end
        
            % 4. get tags of subentities that define it. % not needed
            %numBoudingEntities = line_data(9+j);
            %entitiesTags = zeros(1,numBoudingEntities);
            %for k=1:numBoudingEntities
            %   entitiesTags(k) = line_data(9+j+k);
            %end
    end
    % output structure:
    entity  = struct('ID',entityTag,'Phys_ID',physicalTag);
end

% Get single partitioned entity information:
function entity = get_partitionedEntity(str_line,type)
    
    vector = str2double(regexp(str_line,'-?[\d.]+(?:e-?\d+)?','match'));

    switch type
        case 'node'
            % 1. get entityTag
            entityTag = vector(1);

            % 2. get parent dimention and tag 
            %parentDim = vector(2); % not needed
            parentTag = vector(3);
            
            % 3. get partition tags
            numPartitionTags = vector(4);
            if numPartitionTags > 1 % --> mark it as an interface element!
                j=numPartitionTags; partitionTags = -1;
            else
                j=numPartitionTags; partitionTags = vector(4+j);
            end

            % 4. get entity coordinates % not needed
            % ignore indexes 5+j, 6+j, 7+j

            % 5. get physical tag associated
            numPhysicalTags = vector(8+j);
            if numPhysicalTags == 0 % <-- entity has not physical group!
                physicalTag = -1;
            else
                physicalTag = vector(9+j);
            end

        otherwise
            % 1. get entityTag
            entityTag = vector(1);
        
            % 2. get parent dimention and tag % no needed
            %parentDim = vector(2);
            parentTag = vector(3);
            
            % 3. get partition tags
            numPartitionTags = vector(4);
            if numPartitionTags > 1 % --> mark it as an interface element!
                j=numPartitionTags; partitionTags = -1;
            else
                j=numPartitionTags; partitionTags = vector(4+j);
            end

            % 3. get entity boxing limits (for visualization) % not needed
            % ignore indexes 5+j, 6+j, 7+j, 8+j, 9+j, 10+j
            
            % 4. get physical tag associated
            numPhysicalTags = vector(11+j);
            if numPhysicalTags == 0 % <-- entity has not physical group!
                physicalTag = -1;
            else
                physicalTag = vector(12+j);
            end
        
            % 5. get tags of subentities that define it. % not needed
            %numBoudingEntities = line_data(12+j+k);
            %entitiesTags = zeros(1,numBoudingEntities);
            %for l=1:numBoudingEntities
            %   entitiesTags(l) = line_data(12+j+k+l);
            %end
    end
    % output structure:
    entity  = struct('chld_ID',entityTag,'Prnt_ID',parentTag,...
                    'Part_ID',partitionTags,'Phys_ID',physicalTag);
end

% Get single partitioned entity information:
function V = get_nodes(cells_N,numNodeBlocks,numNodes)

    % allocate space for nodal data
    V = zeros(numNodes,3); % [x,y,z] 

    l = 1; % this is the parameters line
    % Read nodes blocks:   (can be read in parallel!)
    for ent = 1:numNodeBlocks
        % Read Block parameters
        l = l+1;
        line_data = sscanf(cells_N{l},'%d %d %d %d');
        %entityDim = line_data(1);  % not needed
        %entityTag = line_data(2);  % not needed
        %parametric = line_data(3); % not needed
        numNodesInBlock = line_data(4);
        
        % Read Nodes IDs
        nodeTag = zeros(1,numNodesInBlock); % nodeTag
        for i=1:numNodesInBlock
            l = l+1; % update line counter
            nodeTag(i) = sscanf(cells_N{l},'%d');
        end
        
        % Read Nodes Coordinates
        for i=1:numNodesInBlock
            l = l+1; % update line counter
            V(nodeTag(i),:) = sscanf(cells_N{l},'%g %g %g'); % [x(i),y(i),z(i)]
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