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
    std::cout << "Total point-elements found = " << mesh.El.pnt.num_elements() << std::endl;
    std::cout << "Total curve-elements found = " << mesh.El.lin.num_elements() << std::endl;
    std::cout << "Total triangle-elements found = " << mesh.El.tri.num_elements() << std::endl;
    std::cout << "Total quadrilateral-elements found = " << mesh.El.quad.num_elements() << std::endl;
    std::cout << "Total tetrahedron-elements found = " << mesh.El.tet.num_elements() << std::endl;
    std::cout << "Total hexahedron-elements found = " << mesh.El.hex.num_elements() << std::endl;
    std::cout << "Total prism-elements found = " << mesh.El.prism.num_elements() << std::endl;

    return 0;
}

#endif
