function export_test_references()
%EXPORT_TEST_REFERENCES Write parser outputs for pytest regression checks.
%
%   Run from the Matlab/ directory:
%       export_test_references
%
%   This writes one compressed NPZ-compatible MAT file per mesh under
%   ../tests/reference/, using the same array names as gmshparser.as_dict().

    repo_root = fileparts(fileparts(mfilename('fullpath')));
    mesh_dir = fullfile(repo_root, 'meshes');
    ref_dir = fullfile(repo_root, 'tests', 'reference');
    if ~exist(ref_dir, 'dir')
        mkdir(ref_dir);
    end

    meshes = {
        'square_tri_v2.msh',      @GMSHparserV2;
        'square_quad_v2.msh',     @GMSHparserV2;
        'square_mixed_v2.msh',    @GMSHparserV2;
        'extruded_prism_v2.msh',  @GMSHparserV2;
        'extruded_hex_v2.msh',    @GMSHparserV2;
        'extruded_mixed_v2.msh',  @GMSHparserV2;
        'rectangle_v2.msh',       @GMSHparserV2;
        'box_v2.msh',             @GMSHparserV2;
        'square_tri_v4.msh',      @GMSHparserV4;
        'square_quad_v4.msh',     @GMSHparserV4;
        'square_mixed_v4.msh',    @GMSHparserV4;
        'extruded_prism_v4.msh',  @GMSHparserV4;
        'extruded_hex_v4.msh',    @GMSHparserV4;
        'extruded_mixed_v4.msh',  @GMSHparserV4;
        'rectangle_v4.msh',       @GMSHparserV4;
        'box_v4.msh',             @GMSHparserV4;
    };

    for i = 1:size(meshes, 1)
        mesh_name = meshes{i, 1};
        parser = meshes{i, 2};
        mesh_path = fullfile(mesh_dir, mesh_name);
        fprintf('Exporting %s\n', mesh_name);
        [V, VE, SE, LE, PE, mapPhysNames, info] = parser(mesh_path);
        data = matlab_mesh_to_reference(V, VE, SE, LE, PE, mapPhysNames, info);
        out_path = fullfile(ref_dir, replace(mesh_name, '.msh', '.mat'));
        save(out_path, '-struct', 'data', '-v7');
    end
end

function data = matlab_mesh_to_reference(V, VE, SE, LE, PE, mapPhysNames, info)
    data.V = pad_vertices(V, info.Dim);
    data = append_block(data, 'PE', PE, 1);
    data = append_block(data, 'LE', LE, 2);
    data = append_block(data, 'SE_tri', SE.tri, 3);
    data = append_block(data, 'SE_quad', SE.quad, 4);
    data = append_block(data, 'VE_tet', VE.tet, 4);
    data = append_block(data, 'VE_hex', VE.hex, 8);
    data = append_block(data, 'VE_prism', VE.prism, 6);

    data.info_version = info.version;
    data.info_format = info.file_type;
    data.info_endian = info.mode;
    data.info_phys_DIM = info.Dim;
    data.info_num_nodes = size(V, 1);
    data.info_single_domain = double(info.numPartitions <= 1);
    data.info_num_partitions = info.numPartitions;

    tags = cell2mat(keys(mapPhysNames));
    names = values(mapPhysNames);
    data.physical_name_tags = tags(:);
    data.physical_name_values = cellstr(names(:)); % MD: SciPy cannot read MATLAB strings
end

function Vout = pad_vertices(V, dim)
    Vout = zeros(size(V, 1), 3);
    Vout(:, 1:dim) = V(:, 1:dim);
end

function data = append_block(data, prefix, block, nodes_per_elem)
    etov_key = etov_field_name(prefix);

    if isempty(block.Etype)
        data.(etov_key) = zeros(0, nodes_per_elem);
        data.([prefix '_phys_tag']) = zeros(0, 1);
        data.([prefix '_geom_tag']) = zeros(0, 1);
        data.([prefix '_part_tag']) = zeros(0, 1);
        data.([prefix '_Etype']) = zeros(0, 1);
        return;
    end

    num_elements = size(block.Etype, 1);
    data.(etov_key) = block.EToV;
    data.([prefix '_phys_tag']) = block.phys_tag;
    data.([prefix '_geom_tag']) = block.geom_tag;
    data.([prefix '_part_tag']) = block.part_tag;
    data.([prefix '_Etype']) = block.Etype;
end

function key = etov_field_name(prefix)
    if strcmp(prefix, 'PE')
        key = 'PEToV';
    elseif strcmp(prefix, 'LE')
        key = 'LEToV';
    else
        key = [prefix '_EToV'];
    end
end
