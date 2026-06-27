"""Generate tests/reference/*.mat from the current Python parser (one=1).

Prefer Matlab/export_test_references.m for authoritative gold references.
Do not run this script unless you intentionally want Python-native references.
"""

from __future__ import annotations

import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO_ROOT))

import numpy as np
from scipy.io import savemat

import gmshparser
from tests.matlab_reference import mesh_to_reference_dict

MESH_DIR = REPO_ROOT / "meshes"
REFERENCE_DIR = REPO_ROOT / "tests" / "reference"


def main() -> None:
    REFERENCE_DIR.mkdir(parents=True, exist_ok=True)

    for mesh_path in sorted(MESH_DIR.glob("*.msh")):
        if mesh_path.name.endswith("_v2.msh"):
            mesh = gmshparser.parse_v2(mesh_path, one=0)
        elif mesh_path.name.endswith("_v4.msh"):
            mesh = gmshparser.parse_v4(mesh_path, one=0)
        else:
            continue

        data = mesh_to_reference_dict(mesh)
        out_path = REFERENCE_DIR / mesh_path.name.replace(".msh", ".mat")
        savemat(out_path, data, do_compression=True)
        print(f"wrote {out_path.relative_to(REPO_ROOT)}")


if __name__ == "__main__":
    main()
