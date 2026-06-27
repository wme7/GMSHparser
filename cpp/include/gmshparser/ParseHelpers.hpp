#ifndef GMSH_PARSE_HELPERS_HPP
#define GMSH_PARSE_HELPERS_HPP

#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>

#include "ElementTypes.hpp"
#include "GMSHparserTools.hpp"
#include "Types.hpp"

namespace gmshparser {

struct ElementCounters {
    size_t numE1 = 0;
    size_t numE2 = 0;
    size_t numE3 = 0;
    size_t numE4 = 0;
    size_t numE5 = 0;
    size_t numE6 = 0;
    size_t numE8 = 0;
    size_t numE9 = 0;
    size_t numE10 = 0;
    size_t numE11 = 0;
    size_t numE12 = 0;
    size_t numE13 = 0;
    size_t numE26 = 0;
    size_t numE21 = 0;
    size_t numE36 = 0;
    size_t numE29 = 0;
    size_t numE92 = 0;
    size_t numE90 = 0;
    size_t numE15 = 0;

    size_t first_order_total() const
    {
        return numE1 + numE2 + numE3 + numE4 + numE5 + numE6;
    }

    size_t second_order_total() const
    {
        return numE8 + numE9 + numE10 + numE11 + numE12 + numE13;
    }

    size_t third_order_total() const
    {
        return numE26 + numE21 + numE36 + numE29 + numE90 + numE92;
    }
};

struct ElementBlocks {
    ElementBlock& PE;
    ElementBlock& LE;
    ElementBlock& SE_tri;
    ElementBlock& SE_quad;
    ElementBlock& VE_tet;
    ElementBlock& VE_hex;
    ElementBlock& VE_prism;
};

enum class EntityKind { Point, Curve, Surface, Volume };

inline EntityKind entity_kind_for_type(size_t gmsh_type)
{
    switch (lookup_element_type(gmsh_type).geometry) {
    case ElementGeometry::Point:
        return EntityKind::Point;
    case ElementGeometry::Line:
        return EntityKind::Curve;
    case ElementGeometry::Triangle:
    case ElementGeometry::Quadrilateral:
        return EntityKind::Surface;
    case ElementGeometry::Tetrahedron:
    case ElementGeometry::Hexahedron:
    case ElementGeometry::Prism:
        return EntityKind::Volume;
    default:
        throw std::runtime_error("Unsupported Gmsh element type: " + std::to_string(gmsh_type));
    }
}

inline ElementBlock* block_for_gmsh_type(size_t gmsh_type, ElementBlocks blocks)
{
    switch (lookup_element_type(gmsh_type).geometry) {
    case ElementGeometry::Point:
        return &blocks.PE;
    case ElementGeometry::Line:
        return &blocks.LE;
    case ElementGeometry::Triangle:
        return &blocks.SE_tri;
    case ElementGeometry::Quadrilateral:
        return &blocks.SE_quad;
    case ElementGeometry::Tetrahedron:
        return &blocks.VE_tet;
    case ElementGeometry::Hexahedron:
        return &blocks.VE_hex;
    case ElementGeometry::Prism:
        return &blocks.VE_prism;
    default:
        return nullptr;
    }
}

inline size_t* counter_for_gmsh_type(size_t gmsh_type, ElementCounters& counters)
{
    switch (gmsh_type) {
    case 1:
        return &counters.numE1;
    case 2:
        return &counters.numE2;
    case 3:
        return &counters.numE3;
    case 4:
        return &counters.numE4;
    case 5:
        return &counters.numE5;
    case 6:
        return &counters.numE6;
    case 8:
        return &counters.numE8;
    case 9:
        return &counters.numE9;
    case 10:
        return &counters.numE10;
    case 11:
        return &counters.numE11;
    case 12:
        return &counters.numE12;
    case 13:
        return &counters.numE13;
    case 15:
        return &counters.numE15;
    case 21:
        return &counters.numE21;
    case 26:
        return &counters.numE26;
    case 29:
        return &counters.numE29;
    case 36:
        return &counters.numE36;
    case 90:
        return &counters.numE90;
    case 92:
        return &counters.numE92;
    default:
        return nullptr;
    }
}

inline void append_connectivity(
    ElementBlock& block,
    size_t gmsh_type,
    const std::vector<size_t>& indices,
    size_t one)
{
    const size_t expected = gmsh_nodes_per_element(gmsh_type);
    if (indices.size() != expected) {
        throw std::runtime_error(
            "Element connectivity size mismatch for Gmsh type "
            + std::to_string(gmsh_type));
    }
    block.Etype.push_back(gmsh_type);
    for (size_t index : indices) {
        block.EToV.push_back(index - one);
    }
}

inline void assign_v2_tags(ElementBlock& block, const std::vector<size_t>& tags, size_t one)
{
    if (tags.empty()) {
        return;
    }
    block.phys_tag.push_back(static_cast<int>(tags[0]));
    if (tags.size() >= 2) {
        block.geom_tag.push_back(static_cast<int>(tags[1]));
        if (tags.size() >= 4) {
            block.part_tag.push_back(static_cast<int>(tags[3] - one));
        }
    }
}

inline void append_v2_element(
    ElementBlock& block,
    size_t gmsh_type,
    const std::vector<size_t>& line_data,
    size_t numberOfTags,
    size_t one)
{
    const size_t conn_start = 3 + numberOfTags;
    if (line_data.size() <= conn_start) {
        throw std::runtime_error(
            "Missing connectivity for Gmsh type " + std::to_string(gmsh_type));
    }
    append_connectivity(
        block,
        gmsh_type,
        extractVectorBetween(line_data, conn_start, line_data.size()),
        one);
}

inline void assign_v4_element(
    ElementBlock& block,
    size_t gmsh_type,
    const std::vector<size_t>& line_data,
    int phys_tag,
    int geom_tag,
    int part_tag,
    bool single_domain,
    size_t one)
{
    if (line_data.size() <= 1) {
        throw std::runtime_error(
            "Missing connectivity for Gmsh type " + std::to_string(gmsh_type));
    }
    append_connectivity(
        block,
        gmsh_type,
        extractVectorBetween(line_data, 1, line_data.size()),
        one);
    block.phys_tag.push_back(phys_tag);
    block.geom_tag.push_back(geom_tag);
    if (!single_domain) {
        block.part_tag.push_back(part_tag - static_cast<int>(one));
    }
}

inline void validate_and_set_element_order(
    size_t numTotalElem,
    const ElementCounters& counters,
    MeshInfo& info,
    bool debug)
{
    const size_t numElements1stOrder = counters.first_order_total();
    const size_t numElements2ndOrder = counters.second_order_total();
    const size_t numElements3rdOrder = counters.third_order_total();

    if (numElements1stOrder != 0) {
        info.element_order = 1;
        if (debug) {
            std::cout << "Total point-elements found = " << counters.numE15 << std::endl;
            std::cout << "Total line-elements found = " << counters.numE1 << std::endl;
            std::cout << "Total triangle-elements found = " << counters.numE2 << std::endl;
            std::cout << "Total quadrilateral-elements found = " << counters.numE3 << std::endl;
            std::cout << "Total tetrahedron-elements found = " << counters.numE4 << std::endl;
            std::cout << "Total hexahedron-elements found = " << counters.numE5 << std::endl;
            std::cout << "Total prism-elements found = " << counters.numE6 << std::endl;
        }
        if (numTotalElem != numElements1stOrder + counters.numE15) {
            throw std::runtime_error("Total number of elements mismatch");
        }
        return;
    }

    if (numElements2ndOrder != 0) {
        info.element_order = 2;
        if (debug) {
            std::cout << "Total point-elements found = " << counters.numE15 << std::endl;
            std::cout << "Total line-elements found = " << counters.numE8 << std::endl;
            std::cout << "Total triangle-elements found = " << counters.numE9 << std::endl;
            std::cout << "Total quadrilateral-elements found = " << counters.numE10 << std::endl;
            std::cout << "Total tetrahedron-elements found = " << counters.numE11 << std::endl;
            std::cout << "Total hexahedron-elements found = " << counters.numE12 << std::endl;
            std::cout << "Total prism-elements found = " << counters.numE13 << std::endl;
        }
        if (numTotalElem != numElements2ndOrder + counters.numE15) {
            throw std::runtime_error("Total number of elements mismatch");
        }
        return;
    }

    if (numElements3rdOrder != 0) {
        info.element_order = 3;
        if (debug) {
            std::cout << "Total point-elements found = " << counters.numE15 << std::endl;
            std::cout << "Total line-elements found = " << counters.numE26 << std::endl;
            std::cout << "Total triangle-elements found = " << counters.numE21 << std::endl;
            std::cout << "Total quadrilateral-elements found = " << counters.numE36 << std::endl;
            std::cout << "Total tetrahedron-elements found = " << counters.numE29 << std::endl;
            std::cout << "Total hexahedron-elements found = " << counters.numE92 << std::endl;
            std::cout << "Total prism-elements found = " << counters.numE90 << std::endl;
        }
        if (numTotalElem != numElements3rdOrder + counters.numE15) {
            throw std::runtime_error("Total number of elements mismatch");
        }
        return;
    }

    info.element_order = 0;
    if (debug) {
        std::cout << "Total point-elements found = " << counters.numE15 << std::endl;
    }
    if (numTotalElem != counters.numE15) {
        throw std::runtime_error("Total number of elements mismatch");
    }
}

} // namespace gmshparser

#endif
