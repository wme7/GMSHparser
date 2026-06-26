#ifndef GMSH_PARSER_V2
#define GMSH_PARSER_V2

#include "ParseV2.hpp"

#include <iostream>

inline int GMSHparserV2(std::string mesh_file)
{
    auto mesh = gmshparser::parse_gmsh_v2(mesh_file);

    std::cout << "Mesh version " << mesh.info.version << ", Binary " << mesh.info.format
              << ", endian " << mesh.info.endian << std::endl;
    std::cout << "Total vertices found = " << mesh.info.num_nodes << std::endl;
    std::cout << "Total point-elements found = " << mesh.PE.num_elements() << std::endl;
    std::cout << "Total curve-elements found = " << mesh.LE.num_elements() << std::endl;
    std::cout << "Total triangle-elements found = " << mesh.SE_tri.num_elements() << std::endl;
    std::cout << "Total quadrilateral-elements found = " << mesh.SE_quad.num_elements() << std::endl;
    std::cout << "Total tetrahedron-elements found = " << mesh.VE_tet.num_elements() << std::endl;
    std::cout << "Total hexahedron-elements found = " << mesh.VE_hex.num_elements() << std::endl;
    std::cout << "Total prism-elements found = " << mesh.VE_prism.num_elements() << std::endl;

    return 0;
}

#endif
