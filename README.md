# GMSHparser

Parsers for Gmsh ASCII `.msh` files in format **v2.2** and **v4.1**, following the [Gmsh 4.15.2 reference](https://gmsh.info/doc/texinfo/gmsh.html).

The project provides:

- a **C++17 header library** under `cpp/include/gmshparser/`
- a **Python 3 package** (`gmshparser`) built with pybind11
- **Matlab reference implementations** under `Matlab/`

Supported element types: point (15), line (1), triangle (2), quadrilateral (3), tetrahedron (4), hexahedron (5), and prism (6). Binary meshes are rejected.

![](./Matlab/figures/ScreenCapture.png)

## Repository layout

```
cpp/              C++17 header library and C++ tests
python/           pybind11 extension and Python package
Matlab/           reference Matlab parsers and export script
meshes/           example geometries (.geo) and generated meshes (.msh)
tests/            pytest suite and Matlab-compatible reference data
examples/         small Python usage scripts
```

## Test meshes

Generate meshes from the repository root (requires the `gmsh` executable):

```bash
bash meshes/build_meshes.sh
```

Remove generated mesh files:

```bash
bash meshes/clean_meshes.sh
```

## C++ usage

The library is exposed as a CMake `INTERFACE` target `GMSHparser::GMSHparser`. It is header-only and has no external dependencies.

### Build and test

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
ctest --test-dir build --output-on-failure
```

### Parse a mesh

```cpp
#include <gmshparser/ParseV4.hpp>

int main() {
    auto mesh = gmshparser::parse_gmsh_v4("mesh.msh");
    // mesh.V, mesh.SE_tri, mesh.phys_names, mesh.info, ...

    // Matlab-compatible 1-based GMSH tags:
    gmshparser::ParseOptions matlab_opts;
    matlab_opts.one = 0;
    auto mesh_gmsh = gmshparser::parse_gmsh_v4("mesh.msh", matlab_opts);
    return 0;
}
```

`ParseOptions` fields:

- `one` (default `1`): subtract from node/partition indices for 0-based C/Python use; set to `0` to preserve GMSH 1-based tags (Matlab convention).
- `debug` (default `false`): print parser stage messages to stdout.

Legacy entry points that print a short summary are still available:

```cpp
#include <gmshparser/GMSHparserV2.hpp>
GMSHparserV2("mesh.msh");
```

### Use in another CMake project

In-tree:

```cmake
add_subdirectory(path/to/GMSHparser/cpp)
target_link_libraries(my_app PRIVATE GMSHparser::GMSHparser)
```

After installation:

```bash
cmake --install build --prefix /path/to/prefix
```

```cmake
find_package(GMSHparser CONFIG REQUIRED)
target_link_libraries(my_app PRIVATE GMSHparser::GMSHparser)
```

## Python usage

Requires Python >= 3.10 and NumPy.

### Install

From a clone of this repository:

```bash
uv pip install -e .
```

For development (tests, mesh generation, reference export helpers):

```bash
uv pip install -e ".[dev]"
```

### Parse a mesh

```python
import gmshparser

mesh = gmshparser.parse("meshes/square_tri_v2.msh")   # auto-detect v2.2 / v4.1
mesh = gmshparser.parse_v2("meshes/square_tri_v2.msh")
mesh = gmshparser.parse_v4("meshes/box_v4.msh")

# Matlab-compatible indexing (1-based GMSH tags):
mesh = gmshparser.parse_v2("meshes/square_tri_v2.msh", one=0)

# Or pass a ParseOptions object:
opts = gmshparser.ParseOptions()
opts.one = 0
opts.debug = True
mesh = gmshparser.parse_v2("meshes/square_tri_v2.msh", options=opts)

print(mesh.V.shape)
print(mesh.SE_tri.EToV)
print(mesh.physical_names)
print(mesh.info.version)
```

`gmshparser.as_dict(mesh)` returns a flat dictionary of NumPy arrays using the legacy key names (`SE_tri_EToV`, `VE_tet_phys_tag`, …).

### Example scripts

Text summary of mesh contents (nodes, physical groups, element counts):

```bash
uv run python examples/summarize_mesh.py meshes/square_tri_v2.msh
uv run python examples/summarize_mesh.py meshes/box_v4.msh
```

Visualization with matplotlib (`uv sync --extra plot` if needed):

```bash
uv run python examples/plot_mesh.py meshes/square_tri_v2.msh --lines
uv run python examples/plot_mesh.py meshes/box_v4.msh
uv run python examples/plot_mesh.py meshes/box_v4.msh --volume
```

### Run tests

```bash
uv run pytest
```

Reference data live in `tests/reference/`. They are exported from Matlab (`Matlab/export_test_references.m`) and compared with `one=0`. The Python default `one=1` is for 0-based C/Python indexing.

```matlab
cd Matlab
export_test_references
```

## Matlab usage

See `Matlab/GMSHparserV2.m`, `Matlab/GMSHparserV4.m`, and `Matlab/TestParsers.m`.

```matlab
[V, VE, SE, LE, PE, mapPhysNames, info] = GMSHparserV2('../meshes/square_tri_v2.msh');
```

---

Manuel A. Diaz @ Pprime | Univ-Poitiers
