#ifndef GMSH_PARSE_V4_HPP
#define GMSH_PARSE_V4_HPP

#include "Globals.hpp"
#include "GMSHparserTools.hpp"
#include "Types.hpp"

namespace gmshparser {

inline GmshMesh parse_gmsh_v4(const std::string& mesh_file, ParseOptions opts = {})
{
    if (opts.one > 1) {
        throw std::runtime_error("ParseOptions.one must be 0 or 1");
    }

    size_t phys_DIM = 0;
    bool single_domain = true;
    size_t numPartitions = 0;
    const size_t one = opts.one;
    const bool debug = opts.debug;

    std::map<size_t, std::string> phys2names;
    std::map<size_t, int> point2phys, point2part, point2geom;
    std::map<size_t, int> curve2phys, curve2part, curve2geom;
    std::map<size_t, int> surf2phys, surf2part, surf2geom;
    std::map<size_t, int> volm2phys, volm2part, volm2geom;

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
    std::string Entities      = extractBetween(strBuffer, "$Entities\n", "\n$EndEntities");
    std::string PartEntities  = extractBetween(strBuffer, "$PartitionedEntities\n", "\n$EndPartitionedEntities");
    std::string Nodes         = extractBetween(strBuffer, "$Nodes\n", "\n$EndNodes");
    std::string Elements      = extractBetween(strBuffer, "$Elements\n", "\n$EndElements");

    if (MeshFormat.empty())    throw std::runtime_error("Wrong file format");
    if (PhysicalNames.empty()) throw std::runtime_error("No physical names");
    if (Entities.empty())      throw std::runtime_error("No entities found");
    if (Nodes.empty())         throw std::runtime_error("Nodes are missing");
    if (Elements.empty())      throw std::runtime_error("No elements found");

    if (PartEntities.empty()) {
        single_domain = true;
    } else {
        single_domain = false;
    }
    if (debug) std::cout << "Partitioned domain detected" << std::endl;

    std::string line;

    std::stringstream buffer_MF;
    buffer_MF << MeshFormat;

    double version = 1.0;
    size_t format = 0;
    size_t size = 0;
    buffer_MF >> version >> format >> size;

    if (version != 4.1) {
        throw std::runtime_error("Expected mesh format v4.1");
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

    if (single_domain) {
        std::stringstream buffer_Ent;
        buffer_Ent << Entities;

        numPartitions = 1;

        size_t numPoints = 0;
        size_t numCurves = 0;
        size_t numSurfaces = 0;
        size_t numVolumes = 0;
        buffer_Ent >> numPoints >> numCurves >> numSurfaces >> numVolumes;

        if (debug) std::cout << " numPoints: " << numPoints << std::endl;
        if (debug) std::cout << " numCurves: " << numCurves << std::endl;
        if (debug) std::cout << " numSurfaces: " << numSurfaces << std::endl;
        if (debug) std::cout << " numVolumes: " << numVolumes << std::endl;
        std::getline(buffer_Ent, line);

        if (numPoints > 0) {
            for (size_t i = 0; i < numPoints; i++) {
                std::getline(buffer_Ent, line);
                auto [ID, phys_ID] = get_entity(line, 1);
                point2phys[ID] = phys_ID;
            }
        }
        if (numCurves > 0) {
            for (size_t i = 0; i < numCurves; i++) {
                std::getline(buffer_Ent, line);
                auto [ID, phys_ID] = get_entity(line, 2);
                curve2phys[ID] = phys_ID;
            }
        }
        if (numSurfaces > 0) {
            for (size_t i = 0; i < numSurfaces; i++) {
                std::getline(buffer_Ent, line);
                auto [ID, phys_ID] = get_entity(line, 3);
                surf2phys[ID] = phys_ID;
            }
        }
        if (numVolumes > 0) {
            for (size_t i = 0; i < numVolumes; i++) {
                std::getline(buffer_Ent, line);
                auto [ID, phys_ID] = get_entity(line, 4);
                volm2phys[ID] = phys_ID;
            }
        }
    } else {
        std::stringstream buffer_PEnt;
        buffer_PEnt << PartEntities;

        buffer_PEnt >> numPartitions;

        std::getline(buffer_PEnt, line);
        size_t numGhostEntities = 0;
        buffer_PEnt >> numGhostEntities;

        std::getline(buffer_PEnt, line);
        size_t numPoints = 0;
        size_t numCurves = 0;
        size_t numSurfaces = 0;
        size_t numVolumes = 0;
        buffer_PEnt >> numPoints >> numCurves >> numSurfaces >> numVolumes;

        if (debug) std::cout << " numPartitions: " << numPartitions << std::endl;
        if (debug) std::cout << " numPoints: " << numPoints << std::endl;
        if (debug) std::cout << " numCurves: " << numCurves << std::endl;
        if (debug) std::cout << " numSurfaces: " << numSurfaces << std::endl;
        if (debug) std::cout << " numVolumes: " << numVolumes << std::endl;
        std::getline(buffer_PEnt, line);

        if (numPoints > 0) {
            for (size_t i = 0; i < numPoints; i++) {
                std::getline(buffer_PEnt, line);
                auto [chld_ID, prnt_ID, part_ID, phys_ID] = get_partitionedEntity(line, 1);
                point2part[chld_ID] = part_ID;
                point2phys[chld_ID] = phys_ID;
                point2geom[chld_ID] = prnt_ID;
            }
        }
        if (numCurves > 0) {
            for (size_t i = 0; i < numCurves; i++) {
                std::getline(buffer_PEnt, line);
                auto [chld_ID, prnt_ID, part_ID, phys_ID] = get_partitionedEntity(line, 2);
                curve2part[chld_ID] = part_ID;
                curve2phys[chld_ID] = phys_ID;
                curve2geom[chld_ID] = prnt_ID;
            }
        }
        if (numSurfaces > 0) {
            for (size_t i = 0; i < numSurfaces; i++) {
                std::getline(buffer_PEnt, line);
                auto [chld_ID, prnt_ID, part_ID, phys_ID] = get_partitionedEntity(line, 3);
                surf2part[chld_ID] = part_ID;
                surf2phys[chld_ID] = phys_ID;
                surf2geom[chld_ID] = prnt_ID;
            }
        }
        if (numVolumes > 0) {
            for (size_t i = 0; i < numVolumes; i++) {
                std::getline(buffer_PEnt, line);
                auto [chld_ID, prnt_ID, part_ID, phys_ID] = get_partitionedEntity(line, 4);
                volm2part[chld_ID] = part_ID;
                volm2phys[chld_ID] = phys_ID;
                volm2geom[chld_ID] = prnt_ID;
            }
        }
    }

    std::stringstream buffer_N;
    buffer_N << Nodes;

    size_t numNodesBlocks = 0;
    size_t numNodes = 0;
    size_t minNodeIndex = 0;
    size_t maxNodeIndex = 0;
    buffer_N >> numNodesBlocks >> numNodes >> minNodeIndex >> maxNodeIndex;

    if (debug) std::cout << " numNodesBlocks: " << numNodesBlocks << std::endl;
    if (debug) std::cout << " numNodes: " << numNodes << std::endl;
    if (debug) std::cout << " minNodeIndex: " << minNodeIndex - one << std::endl;
    if (debug) std::cout << " maxNodeIndex: " << maxNodeIndex - one << std::endl;

    MArray<double, 2> V = get_nodes(Nodes, numNodesBlocks, numNodes, phys_DIM);

    std::stringstream buffer_E;
    buffer_E << Elements;

    size_t numEntBlocks = 0;
    size_t numTotalElem = 0;
    size_t minElemIndex = 0;
    size_t maxElemIndex = 0;
    buffer_E >> numEntBlocks >> numTotalElem >> minElemIndex >> maxElemIndex;

    if (debug) std::cout << " numEntBlocks: " << numEntBlocks << std::endl;
    if (debug) std::cout << " numTotalElem: " << numTotalElem << std::endl;
    if (debug) std::cout << " minElemIndex: " << minElemIndex - one << std::endl;
    if (debug) std::cout << " maxElemIndex: " << maxElemIndex - one << std::endl;
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

    for (size_t Ent = 0; Ent < numEntBlocks; Ent++) {
        std::getline(buffer_E, line);

        std::stringstream s_stream(line);
        size_t entityDim;
        size_t entityTag;
        size_t elementType;
        size_t numElementsInBlock;
        s_stream >> entityDim >> entityTag >> elementType >> numElementsInBlock;

        for (size_t i = 0; i < numElementsInBlock; i++) {
            std::getline(buffer_E, line);
            auto line_data = str2size_t(line);
            switch (elementType) {
            case 1:
                numE1 = numE1 + 1;
                LE.Etype.push_back(elementType);
                LE.EToV.push_back(line_data[1] - one);
                LE.EToV.push_back(line_data[2] - one);
                LE.phys_tag.push_back(curve2phys[entityTag]);
                if (not(single_domain)) {
                    LE.geom_tag.push_back(curve2geom[entityTag]);
                    LE.part_tag.push_back(curve2part[entityTag] - one);
                } else {
                    LE.geom_tag.push_back(entityTag);
                }
                break;
            case 2:
                numE2 = numE2 + 1;
                SE_tri.Etype.push_back(elementType);
                SE_tri.EToV.push_back(line_data[1] - one);
                SE_tri.EToV.push_back(line_data[2] - one);
                SE_tri.EToV.push_back(line_data[3] - one);
                SE_tri.phys_tag.push_back(surf2phys[entityTag]);
                if (not(single_domain)) {
                    SE_tri.geom_tag.push_back(surf2geom[entityTag]);
                    SE_tri.part_tag.push_back(surf2part[entityTag] - one);
                } else {
                    SE_tri.geom_tag.push_back(entityTag);
                }
                break;
            case 3:
                numE3 = numE3 + 1;
                SE_quad.Etype.push_back(elementType);
                SE_quad.EToV.push_back(line_data[1] - one);
                SE_quad.EToV.push_back(line_data[2] - one);
                SE_quad.EToV.push_back(line_data[3] - one);
                SE_quad.EToV.push_back(line_data[4] - one);
                SE_quad.phys_tag.push_back(surf2phys[entityTag]);
                if (not(single_domain)) {
                    SE_quad.geom_tag.push_back(surf2geom[entityTag]);
                    SE_quad.part_tag.push_back(surf2part[entityTag] - one);
                } else {
                    SE_quad.geom_tag.push_back(entityTag);
                }
                break;
            case 4:
                numE4 = numE4 + 1;
                VE_tet.Etype.push_back(elementType);
                VE_tet.EToV.push_back(line_data[1] - one);
                VE_tet.EToV.push_back(line_data[2] - one);
                VE_tet.EToV.push_back(line_data[3] - one);
                VE_tet.EToV.push_back(line_data[4] - one);
                VE_tet.phys_tag.push_back(volm2phys[entityTag]);
                if (not(single_domain)) {
                    VE_tet.geom_tag.push_back(volm2geom[entityTag]);
                    VE_tet.part_tag.push_back(volm2part[entityTag] - one);
                } else {
                    VE_tet.geom_tag.push_back(entityTag);
                }
                break;
            case 5:
                numE5 = numE5 + 1;
                VE_hex.Etype.push_back(elementType);
                VE_hex.EToV.push_back(line_data[1] - one);
                VE_hex.EToV.push_back(line_data[2] - one);
                VE_hex.EToV.push_back(line_data[3] - one);
                VE_hex.EToV.push_back(line_data[4] - one);
                VE_hex.EToV.push_back(line_data[5] - one);
                VE_hex.EToV.push_back(line_data[6] - one);
                VE_hex.EToV.push_back(line_data[7] - one);
                VE_hex.EToV.push_back(line_data[8] - one);
                VE_hex.phys_tag.push_back(volm2phys[entityTag]);
                if (not(single_domain)) {
                    VE_hex.geom_tag.push_back(volm2geom[entityTag]);
                    VE_hex.part_tag.push_back(volm2part[entityTag] - one);
                } else {
                    VE_hex.geom_tag.push_back(entityTag);
                }
                break;
            case 6:
                numE6 = numE6 + 1;
                VE_prism.Etype.push_back(elementType);
                VE_prism.EToV.push_back(line_data[1] - one);
                VE_prism.EToV.push_back(line_data[2] - one);
                VE_prism.EToV.push_back(line_data[3] - one);
                VE_prism.EToV.push_back(line_data[4] - one);
                VE_prism.EToV.push_back(line_data[5] - one);
                VE_prism.EToV.push_back(line_data[6] - one);
                VE_prism.phys_tag.push_back(volm2phys[entityTag]);
                if (not(single_domain)) {
                    VE_prism.geom_tag.push_back(volm2geom[entityTag]);
                    VE_prism.part_tag.push_back(volm2part[entityTag] - one);
                } else {
                    VE_prism.geom_tag.push_back(entityTag);
                }
                break;
            case 15:
                numE15 = numE15 + 1;
                PE.Etype.push_back(elementType);
                PE.EToV.push_back(line_data[1] - one);
                PE.phys_tag.push_back(point2phys[entityTag]);
                if (not(single_domain)) {
                    PE.geom_tag.push_back(point2geom[entityTag]);
                    PE.part_tag.push_back(point2part[entityTag] - one);
                } else {
                    PE.geom_tag.push_back(entityTag);
                }
                break;
            default:
                throw std::runtime_error("Element type not in list");
            }
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
    mesh.info.single_domain = single_domain;
    mesh.info.num_partitions = numPartitions;

    return mesh;
}

} // namespace gmshparser

#endif
