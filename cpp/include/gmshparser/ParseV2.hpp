#ifndef GMSH_PARSE_V2_HPP
#define GMSH_PARSE_V2_HPP

#include "Globals.hpp"
#include "GMSHparserTools.hpp"
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

    size_t numE1 = 0;
    size_t numE2 = 0;
    size_t numE3 = 0;
    size_t numE4 = 0;
    size_t numE5 = 0;
    size_t numE6 = 0;
    size_t numE15 = 0;

    for (size_t i = 0; i < numTotalElem; i++) {
        std::getline(buffer_E, line);
        auto n = str2size_t(line);
        size_t elementType = n[1];
        size_t numberOfTags = n[2];
        switch (elementType) {
        case 1:
            numE1 = numE1 + 1;
            LE.Etype.push_back(elementType);
            LE.EToV.push_back(n[2 + numberOfTags + 1] - one);
            LE.EToV.push_back(n[2 + numberOfTags + 2] - one);
            if (numberOfTags > 0) {
                auto tags = extractVectorBetween(n, 3, 3 + numberOfTags);
                if (tags.size() >= 1) {
                    LE.phys_tag.push_back(tags[0]);
                    if (tags.size() >= 2) {
                        LE.geom_tag.push_back(tags[1]);
                        if (tags.size() >= 4) {
                            LE.part_tag.push_back(tags[3] - one);
                        }
                    }
                }
            }
            break;
        case 2:
            numE2 = numE2 + 1;
            SE_tri.Etype.push_back(elementType);
            SE_tri.EToV.push_back(n[2 + numberOfTags + 1] - one);
            SE_tri.EToV.push_back(n[2 + numberOfTags + 2] - one);
            SE_tri.EToV.push_back(n[2 + numberOfTags + 3] - one);
            if (numberOfTags > 0) {
                auto tags = extractVectorBetween(n, 3, 3 + numberOfTags);
                if (tags.size() >= 1) {
                    SE_tri.phys_tag.push_back(tags[0]);
                    if (tags.size() >= 2) {
                        SE_tri.geom_tag.push_back(tags[1]);
                        if (tags.size() >= 4) {
                            SE_tri.part_tag.push_back(tags[3] - one);
                        }
                    }
                }
            }
            break;
        case 3:
            numE3 = numE3 + 1;
            SE_quad.Etype.push_back(elementType);
            SE_quad.EToV.push_back(n[2 + numberOfTags + 1] - one);
            SE_quad.EToV.push_back(n[2 + numberOfTags + 2] - one);
            SE_quad.EToV.push_back(n[2 + numberOfTags + 3] - one);
            SE_quad.EToV.push_back(n[2 + numberOfTags + 4] - one);
            if (numberOfTags > 0) {
                auto tags = extractVectorBetween(n, 3, 3 + numberOfTags);
                if (tags.size() >= 1) {
                    SE_quad.phys_tag.push_back(tags[0]);
                    if (tags.size() >= 2) {
                        SE_quad.geom_tag.push_back(tags[1]);
                        if (tags.size() >= 4) {
                            SE_quad.part_tag.push_back(tags[3] - one);
                        }
                    }
                }
            }
            break;
        case 4:
            numE4 = numE4 + 1;
            VE_tet.Etype.push_back(elementType);
            VE_tet.EToV.push_back(n[2 + numberOfTags + 1] - one);
            VE_tet.EToV.push_back(n[2 + numberOfTags + 2] - one);
            VE_tet.EToV.push_back(n[2 + numberOfTags + 3] - one);
            VE_tet.EToV.push_back(n[2 + numberOfTags + 4] - one);
            if (numberOfTags > 0) {
                auto tags = extractVectorBetween(n, 3, 3 + numberOfTags);
                if (tags.size() >= 1) {
                    VE_tet.phys_tag.push_back(tags[0]);
                    if (tags.size() >= 2) {
                        VE_tet.geom_tag.push_back(tags[1]);
                        if (tags.size() >= 4) {
                            VE_tet.part_tag.push_back(tags[3] - one);
                        }
                    }
                }
            }
            break;
        case 5:
            numE5 = numE5 + 1;
            VE_hex.Etype.push_back(elementType);
            VE_hex.EToV.push_back(n[2 + numberOfTags + 1] - one);
            VE_hex.EToV.push_back(n[2 + numberOfTags + 2] - one);
            VE_hex.EToV.push_back(n[2 + numberOfTags + 3] - one);
            VE_hex.EToV.push_back(n[2 + numberOfTags + 4] - one);
            VE_hex.EToV.push_back(n[2 + numberOfTags + 5] - one);
            VE_hex.EToV.push_back(n[2 + numberOfTags + 6] - one);
            VE_hex.EToV.push_back(n[2 + numberOfTags + 7] - one);
            VE_hex.EToV.push_back(n[2 + numberOfTags + 8] - one);
            if (numberOfTags > 0) {
                auto tags = extractVectorBetween(n, 3, 3 + numberOfTags);
                if (tags.size() >= 1) {
                    VE_hex.phys_tag.push_back(tags[0]);
                    if (tags.size() >= 2) {
                        VE_hex.geom_tag.push_back(tags[1]);
                        if (tags.size() >= 4) {
                            VE_hex.part_tag.push_back(tags[3] - one);
                        }
                    }
                }
            }
            break;
        case 6:
            numE6 = numE6 + 1;
            VE_prism.Etype.push_back(elementType);
            VE_prism.EToV.push_back(n[2 + numberOfTags + 1] - one);
            VE_prism.EToV.push_back(n[2 + numberOfTags + 2] - one);
            VE_prism.EToV.push_back(n[2 + numberOfTags + 3] - one);
            VE_prism.EToV.push_back(n[2 + numberOfTags + 4] - one);
            VE_prism.EToV.push_back(n[2 + numberOfTags + 5] - one);
            VE_prism.EToV.push_back(n[2 + numberOfTags + 6] - one);
            if (numberOfTags > 0) {
                auto tags = extractVectorBetween(n, 3, 3 + numberOfTags);
                if (tags.size() >= 1) {
                    VE_prism.phys_tag.push_back(tags[0]);
                    if (tags.size() >= 2) {
                        VE_prism.geom_tag.push_back(tags[1]);
                        if (tags.size() >= 4) {
                            VE_prism.part_tag.push_back(tags[3] - one);
                        }
                    }
                }
            }
            break;
        case 15:
            numE15 = numE15 + 1;
            PE.Etype.push_back(elementType);
            PE.EToV.push_back(n[2 + numberOfTags + 1] - one);
            if (numberOfTags > 0) {
                auto tags = extractVectorBetween(n, 3, 3 + numberOfTags);
                if (tags.size() >= 1) {
                    PE.phys_tag.push_back(tags[0]);
                    if (tags.size() >= 2) {
                        PE.geom_tag.push_back(tags[1]);
                        if (tags.size() >= 4) {
                            PE.part_tag.push_back(tags[3] - one);
                        }
                    }
                }
            }
            break;
        default:
            throw std::runtime_error("Element type not in list");
        }
    }

    if (numTotalElem != (numE15 + numE1 + numE2 + numE3 + numE4 + numE5 + numE6)) {
        throw std::runtime_error("Total number of elements mismatch");
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
