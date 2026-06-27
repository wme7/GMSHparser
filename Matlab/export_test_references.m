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
        'square_extruded_prism_v2.msh',  @GMSHparserV2;
        'square_extruded_hex_v2.msh',    @GMSHparserV2;
        'square_extruded_mixed_v2.msh',  @GMSHparserV2;
        'simple_rectangle_v2.msh',       @GMSHparserV2;
        'simple_box_v2.msh',             @GMSHparserV2;
        'sector_mixed_p1_v2.msh', @GMSHparserV2;
        'sector_mixed_p2_v2.msh', @GMSHparserV2;
        'sector_mixed_p3_v2.msh', @GMSHparserV2;
        'sector_extruded_mixed_p1_v2.msh', @GMSHparserV2;
        'sector_extruded_mixed_p2_v2.msh', @GMSHparserV2;
        'sector_extruded_mixed_p3_v2.msh', @GMSHparserV2;
        'square_tri_v4.msh',      @GMSHparserV4;
        'square_quad_v4.msh',     @GMSHparserV4;
        'square_mixed_v4.msh',    @GMSHparserV4;
        'square_extruded_prism_v4.msh',  @GMSHparserV4;
        'square_extruded_hex_v4.msh',    @GMSHparserV4;
        'square_extruded_mixed_v4.msh',  @GMSHparserV4;
        'simple_rectangle_v4.msh',       @GMSHparserV4;
        'simple_box_v4.msh',             @GMSHparserV4;
        'sector_mixed_p1_v4.msh', @GMSHparserV4;
        'sector_mixed_p2_v4.msh', @GMSHparserV4;
        'sector_mixed_p3_v4.msh', @GMSHparserV4;
        'sector_extruded_mixed_p1_v4.msh', @GMSHparserV4;
        'sector_extruded_mixed_p2_v4.msh', @GMSHparserV4;
        'sector_extruded_mixed_p3_v4.msh', @GMSHparserV4;
    };

    for i = 1:size(meshes, 1)
        mesh_name = meshes{i, 1};
        parser = meshes{i, 2};
        mesh_path = fullfile(mesh_dir, mesh_name);
        fprintf('Exporting %s\n', mesh_name);
        [V, El, mapPhysNames, info] = parser(mesh_path);
        data = matlab_mesh_to_reference(V, El, mapPhysNames, info);
        out_path = fullfile(ref_dir, replace(mesh_name, '.msh', '.mat'));
        save(out_path, '-struct', 'data', '-v7');
    end
end

function data = matlab_mesh_to_reference(V, El, mapPhysNames, info)
    data.V = pad_vertices(V, info.Dim);
    data = append_block(data, 'pnt', El.pnt, 1);
    data = append_block(data, 'lin', El.lin, 2);
    data = append_block(data, 'tri', El.tri, 3);
    data = append_block(data, 'quad', El.quad, 4);
    data = append_block(data, 'tet', El.tet, 4);
    data = append_block(data, 'hex', El.hex, 8);
    data = append_block(data, 'prism', El.prism, 6);

    data.info_version = info.version;
    data.info_format = info.file_type;
    data.info_endian = info.mode;
    data.info_phys_DIM = info.Dim;
    data.info_num_nodes = size(V, 1);
    data.info_single_domain = double(info.numPartitions <= 1);
    data.info_num_partitions = info.numPartitions;
    data.info_element_order = info.element_order;

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
    etov_key = [prefix '_EToV'];

    if isempty(block.Etype)
        data.(etov_key) = zeros(0, nodes_per_elem);
        data.([prefix '_phys_tag']) = zeros(0, 1);
        data.([prefix '_geom_tag']) = zeros(0, 1);
        data.([prefix '_part_tag']) = zeros(0, 1);
        data.([prefix '_Etype']) = zeros(0, 1);
        return;
    end

    data.(etov_key) = block.EToV;
    data.([prefix '_phys_tag']) = block.phys_tag;
    data.([prefix '_geom_tag']) = block.geom_tag;
    data.([prefix '_part_tag']) = block.part_tag;
    data.([prefix '_Etype']) = block.Etype;
end
