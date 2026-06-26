from __future__ import annotations

from pathlib import Path

import gmshparser
import numpy as np
import pytest

from conftest import MESH_DIR, REFERENCE_DIR, mesh_stems
from matlab_reference import compare_mesh_to_reference, load_reference

MESH_PATHS = sorted(MESH_DIR.glob("*.msh"))


@pytest.mark.parametrize("mesh_path", MESH_PATHS, ids=lambda p: p.name)
def test_parse_matches_matlab_reference(mesh_path: Path) -> None:
    reference_path = REFERENCE_DIR / mesh_path.name.replace(".msh", ".mat")
    assert reference_path.exists(), (
        f"Missing reference file {reference_path.name}. "
        "Run Matlab/export_test_references.m from the Matlab/ directory."
    )

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

    for block_name in (
        "LE",
        "SE_tri",
        "SE_quad",
        "VE_tet",
        "VE_hex",
        "VE_prism",
        "PE",
    ):
        native = getattr(mesh_native, block_name)
        gmsh = getattr(mesh_gmsh, block_name)
        if native.num_elements == 0:
            continue
        assert np.array_equal(native.EToV, gmsh.EToV - 1), block_name


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
    assert mesh_v2.PE.num_elements == mesh_v4.PE.num_elements
    assert mesh_v2.LE.num_elements == mesh_v4.LE.num_elements
    assert mesh_v2.SE_tri.num_elements == mesh_v4.SE_tri.num_elements
    assert mesh_v2.VE_tet.num_elements == mesh_v4.VE_tet.num_elements
    assert mesh_v2.VE_hex.num_elements == mesh_v4.VE_hex.num_elements
    assert mesh_v2.VE_prism.num_elements == mesh_v4.VE_prism.num_elements

    # v4.1 can split some quads differently for mixed extruded meshes.
    if stem != "extruded_mixed":
        assert mesh_v2.SE_quad.num_elements == mesh_v4.SE_quad.num_elements

    assert mesh_v2.physical_names == mesh_v4.physical_names
