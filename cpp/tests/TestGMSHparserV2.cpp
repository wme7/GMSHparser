#include <cassert>
#include <iostream>

#include <gmshparser/ParseV2.hpp>

#include "MeshExpectations.hpp"
#include "MeshPath.hpp"

int main()
{
    for (const auto& expected : kV2Expectations) {
        auto mesh = gmshparser::parse_gmsh_v2(meshPath(expected.name));
        assert_mesh_expectation(mesh, expected);
        std::cout << expected.name << ": ok" << std::endl;
    }

    return 0;
}
