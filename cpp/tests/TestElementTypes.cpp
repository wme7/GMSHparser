#include <cassert>
#include <iostream>

#include <gmshparser/ElementTypes.hpp>

int main()
{
    using gmshparser::ElementGeometry;
    using gmshparser::infer_element_order;
    using gmshparser::lookup_element_type;

    const auto tri_p1 = lookup_element_type(2);
    assert(tri_p1.supported);
    assert(tri_p1.geometry == ElementGeometry::Triangle);
    assert(tri_p1.order == 1);
    assert(tri_p1.num_nodes == 3);

    const auto hex_p2 = lookup_element_type(12);
    assert(hex_p2.geometry == ElementGeometry::Hexahedron);
    assert(hex_p2.order == 2);
    assert(hex_p2.num_nodes == 27);

    const auto prism_p3 = lookup_element_type(90);
    assert(prism_p3.geometry == ElementGeometry::Prism);
    assert(prism_p3.order == 3);
    assert(prism_p3.num_nodes == 40);

    assert(!lookup_element_type(999).supported);
    assert(infer_element_order(10, 0, 0) == 1);
    assert(infer_element_order(0, 5, 0) == 2);
    assert(infer_element_order(0, 0, 3) == 3);
    assert(infer_element_order(0, 0, 0, 2) == 0);

    gmshparser::ElementBlock block;
    block.Etype = {9, 9};
    block.EToV = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11};
    assert(gmshparser::nodes_per_element(block) == 6);

    const auto conn = gmshparser::connectivity(block);
    assert(conn.dims()[0] == 2);
    assert(conn.dims()[1] == 6);

    std::cout << "TestElementTypes: ok" << std::endl;
    return 0;
}
