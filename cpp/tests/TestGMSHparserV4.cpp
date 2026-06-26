#include <cassert>
#include <iostream>

#include <gmshparser/ParseV4.hpp>

#include "MeshExpectations.hpp"
#include "MeshPath.hpp"

int main()
{
    for (const auto& expected : kV4Expectations) {
        auto mesh = gmshparser::parse_gmsh_v4(meshPath(expected.name));
        assert_mesh_expectation(mesh, expected);
        std::cout << expected.name << ": ok" << std::endl;
    }

    return 0;
}
