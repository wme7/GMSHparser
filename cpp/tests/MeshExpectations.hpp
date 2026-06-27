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
    std::size_t element_order;
    std::size_t pnt;
    std::size_t lin;
    std::size_t tri;
    std::size_t quad;
    std::size_t tet;
    std::size_t hex;
    std::size_t prism;
};

inline constexpr MeshExpectation kV2Expectations[] = {
    {"square_tri_v2.msh", 2.2, 142, 2, 1, 0, 40, 242, 0, 0, 0, 0},
    {"square_quad_v2.msh", 2.2, 121, 2, 1, 0, 40, 0, 100, 0, 0, 0},
    {"square_mixed_v2.msh", 2.2, 192, 2, 1, 0, 60, 132, 100, 0, 0, 0},
    {"square_extruded_prism_v2.msh", 2.2, 2565, 3, 1, 0, 0, 1888, 320, 0, 0, 3776},
    {"square_extruded_hex_v2.msh", 2.2, 2205, 3, 1, 0, 0, 0, 1120, 0, 1600, 0},
    {"square_extruded_mixed_v2.msh", 2.2, 2415, 3, 1, 0, 0, 968, 880, 0, 800, 1936},
    {"simple_rectangle_v2.msh", 2.2, 92, 2, 1, 0, 32, 150, 0, 0, 0, 0},
    {"simple_box_v2.msh", 2.2, 121, 3, 1, 0, 0, 220, 0, 328, 0, 0},
    {"sector_mixed_p1_v2.msh", 2.2, 441, 2, 1, 0, 80, 400, 200, 0, 0, 0},
    {"sector_mixed_p2_v2.msh", 2.2, 1681, 2, 2, 0, 80, 400, 200, 0, 0, 0},
    {"sector_mixed_p3_v2.msh", 2.2, 3721, 2, 3, 0, 80, 400, 200, 0, 0, 0},
    {"sector_extruded_mixed_p1_v2.msh", 2.2, 2205, 3, 1, 0, 0, 800, 880, 0, 800, 1600},
    {"sector_extruded_mixed_p2_v2.msh", 2.2, 15129, 3, 2, 0, 0, 800, 880, 0, 800, 1600},
    {"sector_extruded_mixed_p3_v2.msh", 2.2, 48373, 3, 3, 0, 0, 800, 880, 0, 800, 1600},
};

inline constexpr MeshExpectation kV4Expectations[] = {
    {"square_tri_v4.msh", 4.1, 142, 2, 1, 0, 40, 242, 0, 0, 0, 0},
    {"square_quad_v4.msh", 4.1, 121, 2, 1, 0, 40, 0, 100, 0, 0, 0},
    {"square_mixed_v4.msh", 4.1, 192, 2, 1, 0, 60, 132, 100, 0, 0, 0},
    {"square_extruded_prism_v4.msh", 4.1, 2565, 3, 1, 0, 0, 1888, 320, 0, 0, 3776},
    {"square_extruded_hex_v4.msh", 4.1, 2205, 3, 1, 0, 0, 0, 1120, 0, 1600, 0},
    {"square_extruded_mixed_v4.msh", 4.1, 2415, 3, 1, 0, 0, 968, 800, 0, 800, 1936},
    {"simple_rectangle_v4.msh", 4.1, 92, 2, 1, 0, 32, 150, 0, 0, 0, 0},
    {"simple_box_v4.msh", 4.1, 121, 3, 1, 0, 0, 220, 0, 328, 0, 0},
    {"sector_mixed_p1_v4.msh", 4.1, 441, 2, 1, 0, 80, 400, 200, 0, 0, 0},
    {"sector_mixed_p2_v4.msh", 4.1, 1681, 2, 2, 0, 80, 400, 200, 0, 0, 0},
    {"sector_mixed_p3_v4.msh", 4.1, 3721, 2, 3, 0, 80, 400, 200, 0, 0, 0},
    {"sector_extruded_mixed_p1_v4.msh", 4.1, 2205, 3, 1, 0, 0, 800, 800, 0, 800, 1600},
    {"sector_extruded_mixed_p2_v4.msh", 4.1, 15129, 3, 2, 0, 0, 800, 800, 0, 800, 1600},
    {"sector_extruded_mixed_p3_v4.msh", 4.1, 48373, 3, 3, 0, 0, 800, 800, 0, 800, 1600},
};

inline void assert_mesh_expectation(const gmshparser::GmshMesh& mesh, const MeshExpectation& expected)
{
    assert(mesh.info.version == expected.version);
    assert(mesh.info.num_nodes == expected.nodes);
    assert(mesh.info.phys_DIM == expected.phys_dim);
    assert(mesh.info.element_order == expected.element_order);
    assert(mesh.El.pnt.num_elements() == expected.pnt);
    assert(mesh.El.lin.num_elements() == expected.lin);
    assert(mesh.El.tri.num_elements() == expected.tri);
    assert(mesh.El.quad.num_elements() == expected.quad);
    assert(mesh.El.tet.num_elements() == expected.tet);
    assert(mesh.El.hex.num_elements() == expected.hex);
    assert(mesh.El.prism.num_elements() == expected.prism);
}

#endif
