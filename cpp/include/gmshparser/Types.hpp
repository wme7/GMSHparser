#ifndef GMSH_PARSER_TYPES_HPP
#define GMSH_PARSER_TYPES_HPP

#include <map>
#include <string>
#include <vector>

#include "MdimArray.hpp"

namespace gmshparser {

struct ParseOptions {
    size_t one = 1;   // 1: 0-based EToV/part_tag; 0: preserve GMSH 1-based tags (Matlab)
    bool debug = false;
};

struct ElementBlock {
    std::vector<size_t> EToV;
    std::vector<int> phys_tag;
    std::vector<int> geom_tag;
    std::vector<int> part_tag; // empty when mesh.info.single_domain is true
    std::vector<int> Etype;

    size_t num_elements() const { return Etype.size(); }

    MArray<size_t, 2> connectivity(size_t nodes_per_elem) const
    {
        return MArray<size_t, 2>({num_elements(), nodes_per_elem}, EToV);
    }
};

struct MeshInfo {
    double version = 0.0;
    size_t format = 0;
    size_t endian = 0;
    size_t phys_DIM = 0;
    size_t num_nodes = 0;
    bool single_domain = true;
    size_t num_partitions = 0;
    size_t element_order = 0; // 0: points only; 1/2/3: global mesh polynomial order
};

struct MeshElements {
    ElementBlock pnt;
    ElementBlock lin;
    ElementBlock tri;
    ElementBlock quad;
    ElementBlock tet;
    ElementBlock hex;
    ElementBlock prism;
};

template <typename Fn>
void for_each_element_block(MeshElements& El, Fn&& fn)
{
    fn(El.pnt);
    fn(El.lin);
    fn(El.tri);
    fn(El.quad);
    fn(El.tet);
    fn(El.hex);
    fn(El.prism);
}

template <typename Fn>
void for_each_element_block(const MeshElements& El, Fn&& fn)
{
    fn(El.pnt);
    fn(El.lin);
    fn(El.tri);
    fn(El.quad);
    fn(El.tet);
    fn(El.hex);
    fn(El.prism);
}

struct GmshMesh {
    MArray<double, 2> V;
    MeshElements El;
    std::map<size_t, std::string> phys_names;
    MeshInfo info;
};

inline void clear_part_tags(GmshMesh& mesh)
{
    for_each_element_block(mesh.El, [](ElementBlock& block) { block.part_tag.clear(); });
}

} // namespace gmshparser

#endif
