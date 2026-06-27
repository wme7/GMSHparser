from __future__ import annotations

from pathlib import Path

import gmshparser

from conftest import MESH_DIR


def test_mesh_describe_square_tri() -> None:
    mesh_path = MESH_DIR / "square_tri_v2.msh"
    mesh = gmshparser.parse_v2(mesh_path)
    text = mesh.describe(path=mesh_path)

    assert "Gmsh v2.2" in text
    assert "triangles" in text
    assert "242" in text
    assert "Physical groups:" in text
    assert "0-based (one=1)" in text


def test_mesh_show_writes_summary(capsys) -> None:
    mesh = gmshparser.parse_v2(MESH_DIR / "square_tri_v2.msh")
    mesh.show()
    captured = capsys.readouterr().out

    assert "Elements:" in captured
    assert "triangles" in captured
    assert "0-based (one=1)" in captured


def test_mesh_repr_compact() -> None:
    mesh = gmshparser.parse_v2(MESH_DIR / "square_tri_v2.msh")

    assert repr(mesh) == "<Mesh 2D v2.2 order=1 nodes=142>"


def test_mesh_indexing_note_one_zero() -> None:
    mesh = gmshparser.parse_v2(MESH_DIR / "square_tri_v2.msh", one=0)

    assert mesh.one == 0
    assert "1-based tags (one=0)" in mesh.describe()
