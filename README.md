# GMSHparser

Parsers for Gmsh ASCII `.msh` files in format **v2.2** and **v4.1**, following the [Gmsh 4.15.2 reference](https://gmsh.info/doc/texinfo/gmsh.html).

The project provides:

- a **C++17 header library** under `cpp/include/gmshparser/`
- a **Python 3 package** (`gmshparser`) built with pybind11
- **Matlab reference implementations** under `Matlab/`

Supported element types (ASCII only; binary meshes are rejected):

| Geometry | Gmsh type IDs | Nodes (P1 / P2 / P3) |
|----------|---------------|----------------------|
| Point | 15 | 1 |
| Line | 1, 8, 26 | 2 / 3 / 4 |
| Triangle | 2, 9, 21 | 3 / 6 / 10 |
| Quadrilateral | 3, 10, 36 | 4 / 9 / 16 |
| Tetrahedron | 4, 11, 29 | 4 / 10 / 20 |
| Hexahedron | 5, 12, 92 | 8 / 27 / 64 |
| Prism | 6, 13, 90 | 6 / 18 / 40 |

High-order elements share the same output buckets as linear ones (`LE`, `SE_tri`, …). Per-element Gmsh type IDs are stored in `Etype`; `info.element_order` reports the global mesh order (1, 2, or 3). Gmsh uses a single polynomial order per mesh — mixed-order files are not supported.

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

The `sector_*` geometries produce curved P1/P2/P3 test meshes (2D and extruded 3D). See notes in `meshes/build_meshes.sh` about experimental P3 prism meshes.

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
mesh = gmshparser.parse_v4("meshes/simple_box_v4.msh")

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
print(mesh.info.element_order)
print(mesh.SE_tri.nodes_per_element)
print(mesh.SE_tri.EToV.shape)
```

`gmshparser.as_dict(mesh)` returns a flat dictionary of NumPy arrays using the legacy key names (`SE_tri_EToV`, `VE_tet_phys_tag`, …).

### Example scripts

Text summary of mesh contents (nodes, physical groups, element counts):

```bash
uv run python examples/summarize_mesh.py meshes/square_tri_v2.msh
uv run python examples/summarize_mesh.py meshes/simple_box_v4.msh
uv run python examples/summarize_mesh.py meshes/sector_mixed_p2_v2.msh
```

Visualization with matplotlib (`uv sync --extra plot` if needed):

```bash
uv run python examples/plot_mesh.py meshes/square_tri_v2.msh --lines
uv run python examples/plot_mesh.py meshes/simple_box_v4.msh
uv run python examples/plot_mesh.py meshes/simple_box_v4.msh --volume
```

### Run tests

```bash
uv run pytest
```

Reference data live in `tests/reference/` (28 meshes: square/simple fixtures plus `sector_*` HO cases). They are exported from Matlab (`Matlab/export_test_references.m`) and compared with `one=0`. The Python default `one=1` is for 0-based C/Python indexing.

```matlab
cd Matlab
export_test_references
```

## Matlab usage

See `Matlab/GMSHparserV2.m`, `Matlab/GMSHparserV4.m`, and `Matlab/TestParsers.m`.

Both parsers return the same four outputs:

```matlab
[V, El, mapPhysNames, info] = GMSHparserV2('../meshes/square_tri_v2.msh');
% or
[V, El, mapPhysNames, info] = GMSHparserV4('../meshes/simple_box_v4.msh');
```

`El` groups all element blocks by geometry (`.pnt`, `.lin`, `.tri`, `.quad`, `.tet`, `.hex`, `.prism`). Each field holds `EToV`, `phys_tag`, `geom_tag`, `part_tag`, and `Etype`. High-order elements share the same buckets as linear ones; use `info.element_order` and per-element `Etype` for order.

```matlab
El.tri.EToV
El.lin.phys_tag
El.tet.part_tag
```

Field names align conceptually with the Python/C++ blocks (`El.tri` ≈ `SE_tri`, `El.tet` ≈ `VE_tet`, …).

---

Manuel A. Diaz @ Pprime | Univ-Poitiers
