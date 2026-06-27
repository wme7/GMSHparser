#ifndef GMSH_PARSER_TOOLS
#define GMSH_PARSER_TOOLS

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//
//   Common tools required for reading GMSH-file in format v2.2 and v4.1 
//
//      Coded by Manuel A. Diaz @ Pprime | Univ-Poitiers, 2022.01.21
//
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

#include <iostream>
#include <iterator>
#include <map>
#include <sstream>
#include <string>
#include <tuple>
#include <vector>

#include "MdimArray.hpp"

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// Get a sub-string from the main string-buffer using two unique delimiters:
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
std::string extractBetween(
    const std::string &buffer,
    const std::string &start_delimiter,
    const std::string &stop_delimiter)
{
    if (buffer.find(start_delimiter) != std::string::npos)
    {
        size_t first_delim_pos = buffer.find(start_delimiter);
        size_t end_pos_of_first_delim = first_delim_pos + start_delimiter.length();
        size_t last_delim_pos = buffer.find(stop_delimiter);

        return buffer.substr(end_pos_of_first_delim,
        last_delim_pos - end_pos_of_first_delim);
    }
    else
    {
        return ""; // an empty string
    }
}

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// Get a sub-vector from a std::vector using two delimiters:
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
std::vector<size_t> extractVectorBetween(
    const std::vector<size_t> Vec,
    const size_t first_index,
    const size_t last_index)
{
    std::vector<size_t>::const_iterator first = Vec.begin() + first_index;
    std::vector<size_t>::const_iterator last = Vec.begin() + last_index;
    std::vector<size_t> subVec(first, last);

    return subVec;
}

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// Build convention map of Boundary Elements (BE) for ParadigmS:
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
std::map<std::string,int> get_BE_type()
{
    std::map<std::string,int> BE_type;
    // Initialize map of BCs
    BE_type["BCfile"]=0;
    BE_type["free"]=1;
    BE_type["wall"]=2;
    BE_type["outflow"]=3;
    BE_type["imposedPressure"]=4;
    BE_type["imposedVelocities"]=5;
    BE_type["axisymmetric_y"]=6;
    BE_type["axisymmetric_x"]=7;
    BE_type["BC_rec"]=10;
    BE_type["free_rec"]=11;
    BE_type["wall_rec"]=12;
    BE_type["outflow_rec"]=13;
    BE_type["imposedPressure_rec"]=14;
    BE_type["imposedVelocities_rec"]=15;
    BE_type["axisymmetric_y_rec"]=16;
    BE_type["axisymmetric_x_rec"]=17;
    BE_type["piston_pressure"]=18;
    BE_type["piston_velocity"]=19;
    BE_type["recordingObject"]=20;
    BE_type["recObj"]=20;
    BE_type["piston_stress"]=21;

    return BE_type;
}

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// Build convention map of Domain Elements (DE) for ParadigmS:
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
std::map<std::string,int> get_DE_type()
{
    std::map<std::string,int> DE_type;
    // Initialize map of DEs
    DE_type["fluid" ]=0;
    DE_type["fluid1"]=1;
    DE_type["fluid2"]=2;
    DE_type["fluid3"]=3;
    DE_type["fluid4"]=4;
    DE_type["solid" ]=5;
    DE_type["solid1"]=6;
    DE_type["solid2"]=7;
    DE_type["solid3"]=8;
    DE_type["solid4"]=9;

    return DE_type;
}

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// Parse string between brackets
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
size_t extractBetweenBrackets(const std::string &name)
{
    if(name.find("[")!=std::string::npos)
    {
        size_t first_delim_pos = name.find("[");
        size_t last_delim_pos = name.find("]");
        std::string strNumber = name.substr(first_delim_pos+1,last_delim_pos);
        return std::stoul(strNumber,nullptr,0); // ID
    }
    else
    {
        return 0; // ID = 0;
    }
}

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// Set a unique id type for the piston BCs
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
size_t parse_BC(const std::string &strName)
{
    bool DEBUG = false; 
    size_t BEtype{0};
    auto id = extractBetweenBrackets(strName);
    if(strName.find("BC_piston_pressure")!=std::string::npos){BEtype=1000+id;}
    if(strName.find("BC_piston_velocity")!=std::string::npos){BEtype=2000+id;}
    if(strName.find( "BC_piston_stress" )!=std::string::npos){BEtype=3000+id;}
    if(DEBUG) std::cout << "active boundary condition, BEtype=" << BEtype << std::endl;
    return BEtype;
}

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// Set a unique id for every recording object
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
size_t parse_rec(const std::string &strName)
{
    bool DEBUG = false; 
    size_t BEtype{0};
    auto id = extractBetweenBrackets(strName);
    if(id<999) {BEtype=600+id;}
    else {std::cout << "problem in parse_rec with the id of the recording object" << std::endl;}
    if(DEBUG) std::cout << "active boundary condition, BEtype=" << BEtype << std::endl;
    return BEtype;
}

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// Split and input strings and return a vector with all double values
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
std::vector<double> str2double(const std::string &str)
{
    std::stringstream ss(str);
    std::istream_iterator<double> begin(ss);
    std::istream_iterator<double> end;
    std::vector<double> values(begin,end);
    return values;
}

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// Split and input strings and return a vector with all size_t values
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
std::vector<size_t> str2size_t(const std::string &str)
{
    std::stringstream ss(str);
    std::istream_iterator<size_t> begin(ss);
    std::istream_iterator<size_t> end;
    std::vector<size_t> values(begin,end);
    return values;
}

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// Get entity Tag and its associated physical Tag.
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
std::tuple<size_t, int> get_entity(const std::string &line, const size_t &Idx)
{
    size_t entityTag;
    size_t numPhysicalTags; 
    int physicalTag;

    // get line data
    auto vector = str2double(line);

    switch (Idx) {
        case 1: // case for nodes
            // 1. get entityTag
            entityTag = int(vector[0]);

            // 2. get entity coordiantes // not needed
            // ignore indexes 1, 2, 3

            // 3. get physical tag associated
            numPhysicalTags = int(vector[4]);
            if (numPhysicalTags==0) {
                physicalTag = -1; // set a negative tag!
            } else {
                physicalTag = int(vector[5]);
            }
            break;
        default: // otherwise
            // 1. get entityTag
            entityTag = int(vector[0]);

            // 2. get entity coordiantes // not needed
            // ignore indexes 1, 2, 3, 4, 5, 6

            // 3. get physical tag associated
            numPhysicalTags = int(vector[7]);
            if (numPhysicalTags==0) {
                physicalTag = -1; // set a negative tag!
            } else {
                physicalTag = int(vector[8]);
            }
            // 4. get tags of subentities. // not needed
            break;
    }
    return {entityTag, physicalTag};
}

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// Get partitioned entity Tags and its associated physical Tag.
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
std::tuple<size_t, size_t, int, int> get_partitionedEntity(const std::string &line, const size_t &Idx)
{
    size_t entityTag, parentTag; 
    size_t numPhysicalTags, numPartitionsTags; 
    int partitionTag, physicalTag;

    // get line data
    auto vector = str2double(line);

    switch (Idx) {
        case 1: // case for nodes
            // 1. get entityTag
            entityTag = int(vector[0]);

            // 2. get parent dimension and tag
            //parentDim = int(vector[1]); // not needed
            parentTag = int(vector[2]);

            // 3. get partitions tags
            numPartitionsTags = int(vector[3]);
            if (numPartitionsTags > 1) { // --> mark it as an interface element!
                partitionTag = -1;
            } else {
                partitionTag = int(vector[4]);
            }

            // 4. get entity coordiantes // not needed
            // ignore indexes 5, 6, 7

            // 5. get physical tag associated
            numPhysicalTags = int(vector[7+numPartitionsTags]);
            if (numPhysicalTags==0) {
                physicalTag = -1; // set a negative tag!
            } else {
                physicalTag = int(vector[8+numPartitionsTags]);
            }
            break;
        default: //otherwise
            // 1. get entityTag
            entityTag = int(vector[0]);

            // 2. get parent dimension and tag
            //parentDim = int(vector[1]); // not needed
            parentTag = int(vector[2]);

            // 3. get partitions tags
            numPartitionsTags = int(vector[3]);
            if (numPartitionsTags > 1) { // --> mark it as an interface element!
                partitionTag = -1; // set a negative tag!
            } else {
                partitionTag = int(vector[4]);
            }

            // 4. get entity coordiantes // not needed
            // ignore indexes 5, 6, 7, 8, 9, 10

            // 5. get physical tag associated
            numPhysicalTags = int(vector[10+numPartitionsTags]);
            if (numPhysicalTags==0) {
                physicalTag = -1;
            } else {
                physicalTag = int(vector[11+numPartitionsTags]);
            }
            break;
    }
    return {entityTag, parentTag, partitionTag, physicalTag};
}

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// Get nodes from block system (GMSG format 4.1)
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
MArray<double,2> get_nodes(const std::string &Nodes, const size_t &numNodesBlocks, const size_t &numNodes, const size_t Dim)
{
    // Allocate output
    MArray<double,2> V({numNodes,Dim},0); // [x(:),y(:),z(:)]

    // Node counter
    size_t n=0;
    size_t nID;

    std::stringstream buffer(Nodes);
    std::string line; 
    std::getline(buffer, line); // l = 1;
    // Read nodes blocks:  (this can be done in parallel!)
    for (size_t i=0; i<numNodesBlocks; i++)
    {
        // update line counter, l = l+1;
        std::getline(buffer, line);
        std::stringstream hearder(line);

        // Read Block parameters
        size_t entityDim;  // not needed
        size_t entityTag;  // not needed
        size_t parametric; // not needed
        size_t numNodesInBlock;
        hearder >> entityDim >> entityTag >> parametric >> numNodesInBlock;

        // Read Nodes IDs
        size_t *nodeTag = new size_t[numNodesInBlock]; // nodeTag
        for (size_t i=0; i<numNodesInBlock; i++)
        {
            std::getline(buffer, line);
            std::stringstream stream(line);
            stream >> nodeTag[i];
        }
        // Read Nodes Coordinates
        for (size_t i=0; i<numNodesInBlock; i++)
        {
            std::getline(buffer, line);
            std::stringstream stream(line);
            nID = nodeTag[i] - 1; // GMSH node tags are 1-based; rows are 0-based
            if (Dim==2) {stream >> V(nID,0) >> V(nID,1);}
            if (Dim==3) {stream >> V(nID,0) >> V(nID,1) >> V(nID,2);}
            n = n+1; // Update node counter
        }
        // Delete temporary new-arrays
        delete [] nodeTag;
    }
    return V;
}

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// Get nodes from block system (GMSH format 2.2)
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
MArray<double,2> get_nodes(const std::string &Nodes, const size_t &numNodes, const size_t Dim) 
{
    // Allocate output
    MArray<double,2> V({numNodes,Dim},0); // [x(:),y(:),z(:)]

    // Node counter
    size_t nodeTag;

    std::stringstream buffer(Nodes);
    std::string line; 
    std::getline(buffer, line); // l = 1;
    // Read nodes blocks:  
    for (size_t i=0; i<numNodes; i++)
    {
        std::getline(buffer, line);
        std::stringstream stream(line);
        if (Dim==2) {stream >> nodeTag >> V(i,0) >> V(i,1);}
        if (Dim==3) {stream >> nodeTag >> V(i,0) >> V(i,1) >> V(i,2);}
    }
    return V;
}
#endif