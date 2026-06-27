from __future__ import annotations

from pathlib import Path

import gmshparser
import numpy as np
import pytest

from conftest import MESH_DIR, REFERENCE_DIR, mesh_stems, reference_mesh_paths
from matlab_reference import compare_mesh_to_reference, load_reference

# Known v2.2 vs v4.1 element-count differences (same geometry, different export):
# - stems: v4 -save-all emits extra point/line elements on partitioned-entity faces.
# - quad: v4 can split extruded quad layers differently than v2.
V2_V4_ELEMENT_COUNT_MISMATCH_STEMS = frozenset({
    "simple_box",
    "simple_rectangle",
})

V2_V4_GEOMETRY_COUNT_MISMATCH_STEMS: dict[str, frozenset[str]] = {
    "quad": frozenset({
        "square_extruded_mixed",
        "sector_extruded_mixed_p1",
        "sector_extruded_mixed_p2",
        "sector_extruded_mixed_p3",
    }),
}

MESH_PATHS = sorted(MESH_DIR.glob("*.msh"))


@pytest.mark.parametrize("mesh_path", reference_mesh_paths(), ids=lambda p: p.name)
def test_parse_matches_matlab_reference(mesh_path: Path) -> None:
    reference_path = REFERENCE_DIR / mesh_path.name.replace(".msh", ".mat")
    if mesh_path.name.endswith("_v2.msh"):
        mesh = gmshparser.parse_v2(mesh_path, one=0)
    else:
        mesh = gmshparser.parse_v4(mesh_path, one=0)

    compare_mesh_to_reference(mesh, load_reference(reference_path))


@pytest.mark.parametrize("mesh_path", MESH_PATHS, ids=lambda p: p.name)
def test_parse_default_one_is_zero_based(mesh_path: Path) -> None:
    if mesh_path.name.endswith("_v2.msh"):
        mesh_native = gmshparser.parse_v2(mesh_path)
        mesh_gmsh = gmshparser.parse_v2(mesh_path, one=0)
    else:
        mesh_native = gmshparser.parse_v4(mesh_path)
        mesh_gmsh = gmshparser.parse_v4(mesh_path, one=0)

    for name in gmshparser.GEOMETRY_BLOCKS:
        native = getattr(mesh_native.El, name)
        gmsh = getattr(mesh_gmsh.El, name)
        if native.num_elements == 0:
            continue
        assert np.array_equal(native.EToV, gmsh.EToV - 1), name


@pytest.mark.parametrize("mesh_path", MESH_PATHS, ids=lambda p: p.name)
def test_parse_auto_detect(mesh_path: Path) -> None:
    mesh = gmshparser.parse(mesh_path)
    if mesh_path.name.endswith("_v2.msh"):
        assert mesh.info.version == 2.2
    else:
        assert mesh.info.version == 4.1


def test_debug_prints(capfd: pytest.CaptureFixture[str]) -> None:
    mesh_path = MESH_DIR / "square_tri_v2.msh"
    gmshparser.parse_v2(mesh_path, debug=True)
    captured, _ = capfd.readouterr()
    assert "numNodes" in captured


def test_parse_options_struct() -> None:
    mesh_path = MESH_DIR / "square_tri_v2.msh"
    opts = gmshparser.ParseOptions()
    opts.one = 0
    opts.debug = False
    mesh = gmshparser.parse_v2(mesh_path, options=opts)
    reference = load_reference(REFERENCE_DIR / "square_tri_v2.mat")
    compare_mesh_to_reference(mesh, reference)


@pytest.mark.parametrize("stem", mesh_stems(MESH_DIR))
def test_v2_v4_geometry_consistency(stem: str, mesh_dir: Path) -> None:
    mesh_v2 = gmshparser.parse_v2(mesh_dir / f"{stem}_v2.msh")
    mesh_v4 = gmshparser.parse_v4(mesh_dir / f"{stem}_v4.msh")

    assert mesh_v2.info.num_nodes == mesh_v4.info.num_nodes
    assert mesh_v2.info.phys_DIM == mesh_v4.info.phys_DIM
    assert mesh_v2.info.element_order == mesh_v4.info.element_order

    if stem not in V2_V4_ELEMENT_COUNT_MISMATCH_STEMS:
        for name in gmshparser.GEOMETRY_BLOCKS:
            if stem in V2_V4_GEOMETRY_COUNT_MISMATCH_STEMS.get(name, frozenset()):
                continue
            assert getattr(mesh_v2.El, name).num_elements == getattr(mesh_v4.El, name).num_elements

    assert mesh_v2.physical_names == mesh_v4.physical_names


@pytest.mark.parametrize(
    ("mesh_name", "order", "le_nodes", "tri_nodes", "hex_nodes", "prism_nodes"),
    [
        ("sector_mixed_p1_v2.msh", 1, 2, 3, 0, 0),
        ("sector_mixed_p2_v2.msh", 2, 3, 6, 0, 0),
        ("sector_mixed_p3_v2.msh", 3, 4, 10, 0, 0),
        ("sector_extruded_mixed_p2_v2.msh", 2, 0, 6, 27, 18),
        ("sector_extruded_mixed_p3_v2.msh", 3, 0, 10, 64, 40),
        ("sector_mixed_p2_v4.msh", 2, 3, 6, 0, 0),
        ("sector_extruded_mixed_p2_v4.msh", 2, 0, 6, 27, 18),
    ],
)
def test_high_order_connectivity_shapes(
    mesh_name: str,
    order: int,
    le_nodes: int,
    tri_nodes: int,
    hex_nodes: int,
    prism_nodes: int,
) -> None:
    mesh_path = MESH_DIR / mesh_name
    if mesh_name.endswith("_v2.msh"):
        mesh = gmshparser.parse_v2(mesh_path)
    else:
        mesh = gmshparser.parse_v4(mesh_path)

    assert mesh.info.element_order == order

    if le_nodes:
        assert mesh.El.lin.nodes_per_element == le_nodes
        assert mesh.El.lin.EToV.shape == (mesh.El.lin.num_elements, le_nodes)
    if tri_nodes:
        assert mesh.El.tri.nodes_per_element == tri_nodes
        assert mesh.El.tri.EToV.shape == (mesh.El.tri.num_elements, tri_nodes)
    if hex_nodes:
        assert mesh.El.hex.nodes_per_element == hex_nodes
        assert mesh.El.hex.EToV.shape == (mesh.El.hex.num_elements, hex_nodes)
    if prism_nodes:
        assert mesh.El.prism.nodes_per_element == prism_nodes
        assert mesh.El.prism.EToV.shape == (mesh.El.prism.num_elements, prism_nodes)
