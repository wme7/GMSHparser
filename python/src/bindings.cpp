#include <pybind11/numpy.h>
#include <pybind11/pybind11.h>
#include <pybind11/stl.h>

#include <algorithm>
#include <cstdint>
#include <fstream>
#include <sstream>
#include <stdexcept>
#include <string>
#include <vector>

#include <gmshparser/ParseV2.hpp>
#include <gmshparser/ParseV4.hpp>

namespace py = pybind11;

namespace {

using index_t = std::uint64_t;

template <typename T>
py::array_t<T> vector_to_1d(const std::vector<T>& data)
{
    py::array_t<T> arr(static_cast<py::ssize_t>(data.size()));
    if (!data.empty()) {
        std::copy(data.begin(), data.end(), arr.mutable_data());
    }
    return arr;
}

template <typename T>
py::array_t<T> buffer_to_2d(const T* data, size_t rows, size_t cols, size_t count)
{
    py::array_t<T> arr({static_cast<py::ssize_t>(rows), static_cast<py::ssize_t>(cols)});
    if (count > 0) {
        std::copy(data, data + count, arr.mutable_data());
    }
    return arr;
}

py::array_t<double> vertices_to_numpy(const MArray<double, 2>& V)
{
    const auto dims = V.dims();
    if (dims.size() != 2) {
        throw std::runtime_error("Vertex array must be 2-dimensional");
    }
    return buffer_to_2d(V.data(), dims[0], dims[1], V.total_size());
}

py::array_t<index_t> etov_to_2d(const std::vector<std::size_t>& data, size_t rows, size_t cols)
{
    py::array_t<index_t> arr({static_cast<py::ssize_t>(rows), static_cast<py::ssize_t>(cols)});
    if (!data.empty()) {
        std::transform(
            data.begin(),
            data.end(),
            arr.mutable_data(),
            [](std::size_t value) { return static_cast<index_t>(value); });
    }
    return arr;
}

struct PyElementBlock {
    py::array_t<index_t> etov;
    py::array_t<std::int32_t> phys_tag;
    py::array_t<std::int32_t> geom_tag;
    py::array_t<std::int32_t> part_tag;
    py::array_t<std::int32_t> etype;
    std::size_t num_elements = 0;
};

PyElementBlock element_block_to_python(const gmshparser::ElementBlock& block, size_t nodes_per_elem)
{
    PyElementBlock out;
    out.num_elements = block.num_elements();
    out.etov = etov_to_2d(block.EToV, out.num_elements, nodes_per_elem);
    out.phys_tag = vector_to_1d<std::int32_t>(block.phys_tag);
    out.geom_tag = vector_to_1d<std::int32_t>(block.geom_tag);
    out.part_tag = vector_to_1d<std::int32_t>(block.part_tag);
    out.etype = vector_to_1d<std::int32_t>(block.Etype);
    return out;
}

struct PyMesh {
    py::array_t<double> V;
    PyElementBlock PE;
    PyElementBlock LE;
    PyElementBlock SE_tri;
    PyElementBlock SE_quad;
    PyElementBlock VE_tet;
    PyElementBlock VE_hex;
    PyElementBlock VE_prism;
    std::map<std::size_t, std::string> physical_names;
    gmshparser::MeshInfo info;
};

PyMesh mesh_to_python(const gmshparser::GmshMesh& mesh)
{
    PyMesh out;
    out.V = vertices_to_numpy(mesh.V);
    out.PE = element_block_to_python(mesh.PE, 1);
    out.LE = element_block_to_python(mesh.LE, 2);
    out.SE_tri = element_block_to_python(mesh.SE_tri, 3);
    out.SE_quad = element_block_to_python(mesh.SE_quad, 4);
    out.VE_tet = element_block_to_python(mesh.VE_tet, 4);
    out.VE_hex = element_block_to_python(mesh.VE_hex, 8);
    out.VE_prism = element_block_to_python(mesh.VE_prism, 6);
    out.physical_names = mesh.phys_names;
    out.info = mesh.info;
    return out;
}

double detect_mesh_version(const std::string& mesh_file)
{
    std::ifstream file(mesh_file);
    if (!file) {
        throw std::runtime_error("Could not open file: " + mesh_file);
    }

    std::stringstream buffer;
    buffer << file.rdbuf();

    std::string strBuffer = buffer.str();
    strBuffer.erase(std::remove(strBuffer.begin(), strBuffer.end(), '\r'), strBuffer.end());

    const auto start = strBuffer.find("$MeshFormat\n");
    if (start == std::string::npos) {
        throw std::runtime_error("Wrong file format");
    }

    const auto end = strBuffer.find("\n$EndMeshFormat", start);
    if (end == std::string::npos) {
        throw std::runtime_error("Wrong file format");
    }

    std::stringstream format_buffer(
        strBuffer.substr(start + std::string("$MeshFormat\n").size(), end - start));

    double version = 0.0;
    format_buffer >> version;
    return version;
}

PyMesh parse_v2_py(const std::string& mesh_file, const gmshparser::ParseOptions& opts = {})
{
    return mesh_to_python(gmshparser::parse_gmsh_v2(mesh_file, opts));
}

PyMesh parse_v4_py(const std::string& mesh_file, const gmshparser::ParseOptions& opts = {})
{
    return mesh_to_python(gmshparser::parse_gmsh_v4(mesh_file, opts));
}

PyMesh parse_py(const std::string& mesh_file, const gmshparser::ParseOptions& opts = {})
{
    const double version = detect_mesh_version(mesh_file);
    if (version == 2.2) {
        return parse_v2_py(mesh_file, opts);
    }
    if (version == 4.1) {
        return parse_v4_py(mesh_file, opts);
    }
    throw std::runtime_error("Unsupported mesh format version: " + std::to_string(version));
}

void bind_element_block(py::module& m, const char* name)
{
    py::class_<PyElementBlock>(m, name)
        .def_readonly("EToV", &PyElementBlock::etov)
        .def_readonly("phys_tag", &PyElementBlock::phys_tag)
        .def_readonly("geom_tag", &PyElementBlock::geom_tag)
        .def_readonly("part_tag", &PyElementBlock::part_tag)
        .def_readonly("Etype", &PyElementBlock::etype)
        .def_readonly("num_elements", &PyElementBlock::num_elements);
}

} // namespace

PYBIND11_MODULE(_gmshparser, m)
{
    m.doc() = "Gmsh .msh file parser (v2.2 and v4.1)";

    py::class_<gmshparser::MeshInfo>(m, "MeshInfo")
        .def_readonly("version", &gmshparser::MeshInfo::version)
        .def_readonly("format", &gmshparser::MeshInfo::format)
        .def_readonly("endian", &gmshparser::MeshInfo::endian)
        .def_readonly("phys_DIM", &gmshparser::MeshInfo::phys_DIM)
        .def_readonly("num_nodes", &gmshparser::MeshInfo::num_nodes)
        .def_readonly("single_domain", &gmshparser::MeshInfo::single_domain)
        .def_readonly("num_partitions", &gmshparser::MeshInfo::num_partitions);

    py::class_<gmshparser::ParseOptions>(m, "ParseOptions")
        .def(py::init<>())
        .def_readwrite("one", &gmshparser::ParseOptions::one)
        .def_readwrite("debug", &gmshparser::ParseOptions::debug);

    bind_element_block(m, "ElementBlock");

    py::class_<PyMesh>(m, "Mesh")
        .def_readonly("V", &PyMesh::V)
        .def_readonly("PE", &PyMesh::PE)
        .def_readonly("LE", &PyMesh::LE)
        .def_readonly("SE_tri", &PyMesh::SE_tri)
        .def_readonly("SE_quad", &PyMesh::SE_quad)
        .def_readonly("VE_tet", &PyMesh::VE_tet)
        .def_readonly("VE_hex", &PyMesh::VE_hex)
        .def_readonly("VE_prism", &PyMesh::VE_prism)
        .def_readonly("physical_names", &PyMesh::physical_names)
        .def_readonly("info", &PyMesh::info);

    m.def(
        "parse_v2",
        &parse_v2_py,
        py::arg("path"),
        py::arg("options") = gmshparser::ParseOptions{},
        "Parse a Gmsh v2.2 mesh (options.one=1 gives 0-based indices; one=0 preserves GMSH tags).");
    m.def(
        "parse_v4",
        &parse_v4_py,
        py::arg("path"),
        py::arg("options") = gmshparser::ParseOptions{},
        "Parse a Gmsh v4.1 mesh (options.one=1 gives 0-based indices; one=0 preserves GMSH tags).");
    m.def(
        "parse",
        &parse_py,
        py::arg("path"),
        py::arg("options") = gmshparser::ParseOptions{},
        "Parse a Gmsh mesh, auto-detecting v2.2 or v4.1.");
}
