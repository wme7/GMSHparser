#ifndef GMSH_PARSE_V2_HPP
#define GMSH_PARSE_V2_HPP

#include "ElementTypes.hpp"
#include "Globals.hpp"
#include "GMSHparserTools.hpp"
#include "ParseHelpers.hpp"
#include "Types.hpp"

namespace gmshparser {

inline GmshMesh parse_gmsh_v2(const std::string& mesh_file, ParseOptions opts = {})
{
    if (opts.one > 1) {
        throw std::runtime_error("ParseOptions.one must be 0 or 1");
    }

    size_t phys_DIM = 0;
    const size_t one = opts.one;
    const bool debug = opts.debug;

    std::map<size_t, std::string> phys2names;

    std::ifstream file(mesh_file);
    if (!file) {
        throw std::runtime_error("Could not open file: " + mesh_file);
    }

    std::stringstream buffer;
    buffer << file.rdbuf();
    file.close();

    std::string strBuffer = buffer.str();
    strBuffer.erase(std::remove(strBuffer.begin(), strBuffer.end(), '\r'), strBuffer.end());

    std::string MeshFormat    = extractBetween(strBuffer, "$MeshFormat\n", "\n$EndMeshFormat");
    std::string PhysicalNames = extractBetween(strBuffer, "$PhysicalNames\n", "\n$EndPhysicalNames");
    std::string Nodes         = extractBetween(strBuffer, "$Nodes\n", "\n$EndNodes");
    std::string Elements      = extractBetween(strBuffer, "$Elements\n", "\n$EndElements");

    if (MeshFormat.empty())    throw std::runtime_error("Wrong file format");
    if (PhysicalNames.empty()) throw std::runtime_error("No physical names");
    if (Nodes.empty())         throw std::runtime_error("Nodes are missing");
    if (Elements.empty())      throw std::runtime_error("No elements found");

    std::string line;

    std::stringstream buffer_MF;
    buffer_MF << MeshFormat;

    double version = 1.0;
    size_t format = 0;
    size_t size = 0;
    buffer_MF >> version >> format >> size;

    if (version != 2.2) {
        throw std::runtime_error("Expected mesh format v2.2");
    }
    if (format != 0) {
        throw std::runtime_error("Binary file not allowed");
    }

    std::stringstream buffer_PN;
    buffer_PN << PhysicalNames;

    size_t num_physical_groups = 0;
    buffer_PN >> num_physical_groups;

    if (debug) std::cout << "num_physical_groups: " << num_physical_groups << std::endl;

    for (size_t i = 0; i < num_physical_groups; ++i) {
        std::getline(buffer_PN, line);
        size_t phys_dim, phys_id;
        std::string phys_name;
        buffer_PN >> phys_dim >> phys_id >> phys_name;

        phys_name.erase(std::remove(phys_name.begin(), phys_name.end(), '"'), phys_name.end());
        phys2names[phys_id] = phys_name;
        phys_DIM = phys_DIM > phys_dim ? phys_DIM : phys_dim;

        if (debug) std::cout << " Physical Name: " << phys_name << std::endl;
        if (debug) std::cout << " Physical ID: " << phys_id << std::endl;
        if (debug) std::cout << " Entity Dim: " << phys_dim << std::endl;
    }

    std::stringstream buffer_N;
    buffer_N << Nodes;

    size_t numNodes = 0;
    buffer_N >> numNodes;

    if (debug) std::cout << " numNodes: " << numNodes << std::endl;

    MArray<double, 2> V = get_nodes(Nodes, numNodes, phys_DIM);

    std::stringstream buffer_E;
    buffer_E << Elements;

    size_t numTotalElem = 0;
    buffer_E >> numTotalElem;

    if (debug) std::cout << " numTotalElem: " << numTotalElem << std::endl;
    std::getline(buffer_E, line);

    ElementBlock PE;
    ElementBlock LE;
    ElementBlock SE_tri;
    ElementBlock SE_quad;
    ElementBlock VE_tet;
    ElementBlock VE_hex;
    ElementBlock VE_prism;

    ElementBlocks blocks{PE, LE, SE_tri, SE_quad, VE_tet, VE_hex, VE_prism};
    ElementCounters counters;

    for (size_t i = 0; i < numTotalElem; i++) {
        std::getline(buffer_E, line);
        auto n = str2size_t(line);
        if (n.size() < 3) {
            throw std::runtime_error("Malformed element line");
        }

        const size_t elementType = n[1];
        const size_t numberOfTags = n[2];

        if (!is_supported_element_type(elementType)) {
            throw std::runtime_error("Element type not in list");
        }

        ElementBlock* block = block_for_gmsh_type(elementType, blocks);
        size_t* counter = counter_for_gmsh_type(elementType, counters);
        if (block == nullptr || counter == nullptr) {
            throw std::runtime_error("Element type not in list");
        }

        ++(*counter);
        append_v2_element(*block, elementType, n, numberOfTags, one);
        if (numberOfTags > 0) {
            assign_v2_tags(*block, extractVectorBetween(n, 3, 3 + numberOfTags), one);
        }
    }

    GmshMesh mesh;
    mesh.V = std::move(V);
    mesh.PE = std::move(PE);
    mesh.LE = std::move(LE);
    mesh.SE_tri = std::move(SE_tri);
    mesh.SE_quad = std::move(SE_quad);
    mesh.VE_tet = std::move(VE_tet);
    mesh.VE_hex = std::move(VE_hex);
    mesh.VE_prism = std::move(VE_prism);
    mesh.phys_names = std::move(phys2names);
    mesh.info.version = version;
    mesh.info.format = format;
    mesh.info.endian = size;
    mesh.info.phys_DIM = phys_DIM;
    mesh.info.num_nodes = numNodes;

    validate_and_set_element_order(numTotalElem, counters, mesh.info, debug);

    size_t num_partitions = 1;
    size_t max_part_tag = 0;
    bool has_partition_tag = false;
    auto consider_part_tags = [&](const ElementBlock& block) {
        for (int tag : block.part_tag) {
            if (tag > 0) {
                has_partition_tag = true;
                max_part_tag = std::max(max_part_tag, static_cast<size_t>(tag));
            }
        }
    };
    consider_part_tags(mesh.PE);
    consider_part_tags(mesh.LE);
    consider_part_tags(mesh.SE_tri);
    consider_part_tags(mesh.SE_quad);
    consider_part_tags(mesh.VE_tet);
    consider_part_tags(mesh.VE_hex);
    consider_part_tags(mesh.VE_prism);
    if (has_partition_tag) {
        num_partitions = max_part_tag;
    }
    mesh.info.num_partitions = num_partitions;
    mesh.info.single_domain = num_partitions <= 1;
    if (mesh.info.single_domain) {
        clear_part_tags(mesh);
    }

    return mesh;
}

} // namespace gmshparser

#endif
