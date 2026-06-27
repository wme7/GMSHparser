#ifndef GMSH_PARSER_ELEMENT_TYPES_HPP
#define GMSH_PARSER_ELEMENT_TYPES_HPP

#include <cstddef>
#include <stdexcept>
#include <string>

#include "Types.hpp"

namespace gmshparser {

enum class ElementGeometry {
    Point,
    Line,
    Triangle,
    Quadrilateral,
    Tetrahedron,
    Hexahedron,
    Prism,
    Unknown,
};

struct ElementTypeInfo {
    ElementGeometry geometry = ElementGeometry::Unknown;
    size_t order = 0;       // polynomial order: 1, 2, or 3
    size_t num_nodes = 0;
    bool supported = false;
};

inline ElementTypeInfo lookup_element_type(size_t gmsh_type)
{
    switch (gmsh_type) {
    case 1:
        return {ElementGeometry::Line, 1, 2, true};
    case 8:
        return {ElementGeometry::Line, 2, 3, true};
    case 26:
        return {ElementGeometry::Line, 3, 4, true};

    case 2:
        return {ElementGeometry::Triangle, 1, 3, true};
    case 9:
        return {ElementGeometry::Triangle, 2, 6, true};
    case 21:
        return {ElementGeometry::Triangle, 3, 10, true};

    case 3:
        return {ElementGeometry::Quadrilateral, 1, 4, true};
    case 10:
        return {ElementGeometry::Quadrilateral, 2, 9, true};
    case 36:
        return {ElementGeometry::Quadrilateral, 3, 16, true};

    case 4:
        return {ElementGeometry::Tetrahedron, 1, 4, true};
    case 11:
        return {ElementGeometry::Tetrahedron, 2, 10, true};
    case 29:
        return {ElementGeometry::Tetrahedron, 3, 20, true};

    case 5:
        return {ElementGeometry::Hexahedron, 1, 8, true};
    case 12:
        return {ElementGeometry::Hexahedron, 2, 27, true};
    case 92:
        return {ElementGeometry::Hexahedron, 3, 64, true};

    case 6:
        return {ElementGeometry::Prism, 1, 6, true};
    case 13:
        return {ElementGeometry::Prism, 2, 18, true};
    case 90:
        return {ElementGeometry::Prism, 3, 40, true};

    case 15:
        return {ElementGeometry::Point, 0, 1, true};

    default:
        return {};
    }
}

inline bool is_supported_element_type(size_t gmsh_type)
{
    return lookup_element_type(gmsh_type).supported;
}

inline size_t gmsh_nodes_per_element(size_t gmsh_type)
{
    const ElementTypeInfo info = lookup_element_type(gmsh_type);
    if (!info.supported) {
        throw std::runtime_error("Unsupported Gmsh element type: " + std::to_string(gmsh_type));
    }
    return info.num_nodes;
}

inline size_t nodes_per_element(const ElementBlock& block)
{
    const size_t count = block.num_elements();
    if (count == 0) {
        return 0;
    }
    if (block.EToV.size() % count != 0) {
        throw std::runtime_error("EToV size is not divisible by element count");
    }
    return block.EToV.size() / count;
}

inline MArray<size_t, 2> connectivity(const ElementBlock& block)
{
    const size_t count = block.num_elements();
    const size_t width = nodes_per_element(block);
    return MArray<size_t, 2>({count, width}, block.EToV);
}

inline size_t infer_element_order(
    size_t num_first_order,
    size_t num_second_order,
    size_t num_third_order,
    size_t num_points = 0)
{
    if (num_first_order != 0) {
        return 1;
    }
    if (num_second_order != 0) {
        return 2;
    }
    if (num_third_order != 0) {
        return 3;
    }
    if (num_points != 0) {
        return 0;
    }
    return 0;
}

} // namespace gmshparser

#endif
