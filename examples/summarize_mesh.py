"""Print a human-readable summary of a Gmsh .msh file.

Programmatic use: ``mesh = gmshparser.parse(path); mesh.show()``.
"""

from __future__ import annotations

import argparse
from pathlib import Path

import gmshparser


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mesh", type=Path, help="Path to a .msh file")
    parser.add_argument(
        "--one",
        type=int,
        default=1,
        choices=(0, 1),
        help="Index offset: 1 → 0-based Python indices (default), 0 → preserve Gmsh tags",
    )
    args = parser.parse_args()
    mesh = gmshparser.parse(args.mesh, one=args.one)
    mesh.show(path=args.mesh)


if __name__ == "__main__":
    main()
