#ifndef GMSH_PARSE_V4_HPP
#define GMSH_PARSE_V4_HPP

#include "ElementTypes.hpp"
#include "Globals.hpp"
#include "GMSHparserTools.hpp"
#include "ParseHelpers.hpp"
#include "Types.hpp"

namespace gmshparser {

namespace detail {

inline void resolve_v4_entity_tags(
    EntityKind kind,
    size_t entityTag,
    bool single_domain,
    const std::map<size_t, int>& point2phys,
    const std::map<size_t, int>& point2geom,
    const std::map<size_t, int>& point2part,
    const std::map<size_t, int>& curve2phys,
    const std::map<size_t, int>& curve2geom,
    const std::map<size_t, int>& curve2part,
    const std::map<size_t, int>& surf2phys,
    const std::map<size_t, int>& surf2geom,
    const std::map<size_t, int>& surf2part,
    const std::map<size_t, int>& volm2phys,
    const std::map<size_t, int>& volm2geom,
    const std::map<size_t, int>& volm2part,
    int& phys_tag,
    int& geom_tag,
    int& part_tag)
{
    switch (kind) {
    case EntityKind::Point:
        phys_tag = point2phys.at(entityTag);
        geom_tag = single_domain ? static_cast<int>(entityTag) : point2geom.at(entityTag);
        part_tag = point2part.count(entityTag) ? point2part.at(entityTag) : 0;
        break;
    case EntityKind::Curve:
        phys_tag = curve2phys.at(entityTag);
        geom_tag = single_domain ? static_cast<int>(entityTag) : curve2geom.at(entityTag);
        part_tag = curve2part.count(entityTag) ? curve2part.at(entityTag) : 0;
        break;
    case EntityKind::Surface:
        phys_tag = surf2phys.at(entityTag);
        geom_tag = single_domain ? static_cast<int>(entityTag) : surf2geom.at(entityTag);
        part_tag = surf2part.count(entityTag) ? surf2part.at(entityTag) : 0;
        break;
    case EntityKind::Volume:
        phys_tag = volm2phys.at(entityTag);
        geom_tag = single_domain ? static_cast<int>(entityTag) : volm2geom.at(entityTag);
        part_tag = volm2part.count(entityTag) ? volm2part.at(entityTag) : 0;
        break;
    }
}

} // namespace detail

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

    MeshElements El;
    ElementCounters counters;

    for (size_t Ent = 0; Ent < numEntBlocks; Ent++) {
        std::getline(buffer_E, line);

        std::stringstream s_stream(line);
        size_t entityDim;
        size_t entityTag;
        size_t elementType;
        size_t numElementsInBlock;
        s_stream >> entityDim >> entityTag >> elementType >> numElementsInBlock;

        if (!is_supported_element_type(elementType)) {
            throw std::runtime_error("Element type not in list");
        }

        ElementBlock* block = block_for_gmsh_type(elementType, El);
        size_t* counter = counter_for_gmsh_type(elementType, counters);
        if (block == nullptr || counter == nullptr) {
            throw std::runtime_error("Element type not in list");
        }

        const EntityKind entity_kind = entity_kind_for_type(elementType);

        for (size_t i = 0; i < numElementsInBlock; i++) {
            std::getline(buffer_E, line);
            auto line_data = str2size_t(line);

            int phys_tag = 0;
            int geom_tag = 0;
            int part_tag = 0;
            detail::resolve_v4_entity_tags(
                entity_kind,
                entityTag,
                single_domain,
                point2phys,
                point2geom,
                point2part,
                curve2phys,
                curve2geom,
                curve2part,
                surf2phys,
                surf2geom,
                surf2part,
                volm2phys,
                volm2geom,
                volm2part,
                phys_tag,
                geom_tag,
                part_tag);

            ++(*counter);
            assign_v4_element(
                *block,
                elementType,
                line_data,
                phys_tag,
                geom_tag,
                part_tag,
                single_domain,
                one);
        }
    }

    GmshMesh mesh;
    mesh.V = std::move(V);
    mesh.El = std::move(El);
    mesh.phys_names = std::move(phys2names);
    mesh.info.version = version;
    mesh.info.format = format;
    mesh.info.endian = size;
    mesh.info.phys_DIM = phys_DIM;
    mesh.info.num_nodes = numNodes;
    mesh.info.single_domain = single_domain;
    mesh.info.num_partitions = numPartitions;

    validate_and_set_element_order(numTotalElem, counters, mesh.info, debug);

    return mesh;
}

} // namespace gmshparser

#endif
