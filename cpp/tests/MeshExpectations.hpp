#ifndef GMSH_TEST_MESH_EXPECTATIONS_HPP
#define GMSH_TEST_MESH_EXPECTATIONS_HPP

#include <cassert>
#include <cstddef>

#include <gmshparser/Types.hpp>

struct MeshExpectation {
    const char* name;
    double version;
    std::size_t nodes;
    std::size_t phys_dim;
    std::size_t pe;
    std::size_t le;
    std::size_t tri;
    std::size_t quad;
    std::size_t tet;
    std::size_t hex;
    std::size_t prism;
};

inline constexpr MeshExpectation kV2Expectations[] = {
    {"square_tri_v2.msh", 2.2, 142, 2, 0, 40, 242, 0, 0, 0, 0},
    {"square_quad_v2.msh", 2.2, 121, 2, 0, 40, 0, 100, 0, 0, 0},
    {"square_mixed_v2.msh", 2.2, 192, 2, 0, 60, 132, 100, 0, 0, 0},
    {"square_extruded_prism_v2.msh", 2.2, 2565, 3, 0, 0, 1888, 320, 0, 0, 3776},
    {"square_extruded_hex_v2.msh", 2.2, 2205, 3, 0, 0, 0, 1120, 0, 1600, 0},
    {"square_extruded_mixed_v2.msh", 2.2, 2415, 3, 0, 0, 968, 880, 0, 800, 1936},
    {"simple_rectangle_v2.msh", 2.2, 92, 2, 0, 32, 150, 0, 0, 0, 0},
    {"simple_box_v2.msh", 2.2, 121, 3, 0, 0, 220, 0, 328, 0, 0},
};

inline constexpr MeshExpectation kV4Expectations[] = {
    {"square_tri_v4.msh", 4.1, 142, 2, 0, 40, 242, 0, 0, 0, 0},
    {"square_quad_v4.msh", 4.1, 121, 2, 0, 40, 0, 100, 0, 0, 0},
    {"square_mixed_v4.msh", 4.1, 192, 2, 0, 60, 132, 100, 0, 0, 0},
    {"square_extruded_prism_v4.msh", 4.1, 2565, 3, 0, 0, 1888, 320, 0, 0, 3776},
    {"square_extruded_hex_v4.msh", 4.1, 2205, 3, 0, 0, 0, 1120, 0, 1600, 0},
    {"square_extruded_mixed_v4.msh", 4.1, 2415, 3, 0, 0, 968, 800, 0, 800, 1936},
    {"simple_rectangle_v4.msh", 4.1, 92, 2, 0, 32, 150, 0, 0, 0, 0},
    {"simple_box_v4.msh", 4.1, 121, 3, 0, 0, 220, 0, 328, 0, 0},
};

inline void assert_mesh_expectation(const gmshparser::GmshMesh& mesh, const MeshExpectation& expected)
{
    assert(mesh.info.version == expected.version);
    assert(mesh.info.num_nodes == expected.nodes);
    assert(mesh.info.phys_DIM == expected.phys_dim);
    assert(mesh.PE.num_elements() == expected.pe);
    assert(mesh.LE.num_elements() == expected.le);
    assert(mesh.SE_tri.num_elements() == expected.tri);
    assert(mesh.SE_quad.num_elements() == expected.quad);
    assert(mesh.VE_tet.num_elements() == expected.tet);
    assert(mesh.VE_hex.num_elements() == expected.hex);
    assert(mesh.VE_prism.num_elements() == expected.prism);
}

#endif
