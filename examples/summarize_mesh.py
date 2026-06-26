"""Print a human-readable summary of a Gmsh .msh file."""

from __future__ import annotations

import argparse
from collections import Counter
from pathlib import Path

import gmshparser
import numpy as np
from gmshparser import ElementBlock, Mesh

AXES = "xyz"


def format_bbox(mesh: Mesh) -> str:
    dim = mesh.info.phys_DIM
    coords = mesh.V[:, :dim]
    parts = []
    for i in range(dim):
        lo, hi = coords[:, i].min(), coords[:, i].max()
        parts.append(f"{AXES[i]} ∈ [{lo:.4g}, {hi:.4g}]")
    return ", ".join(parts)


def infer_physical_dimensions(mesh: Mesh) -> dict[int, int]:
    """Guess physical-group dimension from which element blocks reference each tag."""
    dims: dict[int, int] = {}
    blocks: list[tuple[int, ElementBlock]] = [
        (1, mesh.LE),
        (2, mesh.SE_tri),
        (2, mesh.SE_quad),
        (3, mesh.VE_tet),
        (3, mesh.VE_hex),
        (3, mesh.VE_prism),
    ]
    for dim, block in blocks:
        if block.num_elements == 0:
            continue
        for tag in np.unique(block.phys_tag):
            tag = int(tag)
            dims[tag] = max(dims.get(tag, 0), dim)
    return dims


def count_by_phys_tag(block: ElementBlock) -> Counter[int]:
    if block.num_elements == 0:
        return Counter()
    tags, counts = np.unique(block.phys_tag, return_counts=True)
    return Counter(dict(zip(tags.astype(int), counts.astype(int))))


def phys_name(mesh: Mesh, tag: int) -> str:
    return mesh.physical_names.get(tag, "?")


def print_header(mesh_path: Path, mesh: Mesh) -> None:
    info = mesh.info
    encoding = "ASCII" if info.format == 0 else "binary"
    print(f"Mesh: {mesh_path}")
    print(f"  Gmsh v{info.version}, {encoding}, {info.phys_DIM}D")
    print(f"  Nodes: {info.num_nodes}")
    print(f"  Bounding box: {format_bbox(mesh)}")


def print_physical_groups(mesh: Mesh) -> None:
    if not mesh.physical_names:
        return
    print("\nPhysical groups:")
    dims = infer_physical_dimensions(mesh)
    for tag in sorted(mesh.physical_names):
        dim = dims.get(tag, "?")
        print(f"  tag {tag:3d}  {mesh.physical_names[tag]!r}  (dim {dim})")


def print_element_inventory(mesh: Mesh) -> None:
    inventory = [
        ("points", mesh.PE),
        ("lines", mesh.LE),
        ("triangles", mesh.SE_tri),
        ("quads", mesh.SE_quad),
        ("tets", mesh.VE_tet),
        ("hexes", mesh.VE_hex),
        ("prisms", mesh.VE_prism),
    ]
    present = [(label, block) for label, block in inventory if block.num_elements > 0]
    if not present:
        print("\nElements: (none)")
        return
    print("\nElements:")
    for label, block in present:
        print(f"  {label:10s}  {block.num_elements:6d}")


def print_counts_by_physical_group(mesh: Mesh) -> None:
    sections: list[tuple[str, ElementBlock]] = [
        ("line", mesh.LE),
        ("triangle", mesh.SE_tri),
        ("quad", mesh.SE_quad),
        ("tet", mesh.VE_tet),
        ("hex", mesh.VE_hex),
        ("prism", mesh.VE_prism),
    ]
    printed = False
    for elem_label, block in sections:
        counts = count_by_phys_tag(block)
        if not counts:
            continue
        if not printed:
            print("\nElements by physical group:")
            printed = True
        for tag in sorted(counts):
            name = phys_name(mesh, tag)
            n = counts[tag]
            plural = f"{elem_label}{'s' if n != 1 else ''}"
            print(f"  {name} (tag {tag}): {n} {plural}")


def print_partition_info(mesh: Mesh) -> None:
    info = mesh.info
    if info.single_domain:
        return
    print(f"\nPartitions: {info.num_partitions} (multi-domain mesh)")
    volume_blocks = [
        ("tet", mesh.VE_tet),
        ("hex", mesh.VE_hex),
        ("prism", mesh.VE_prism),
    ]
    for label, block in volume_blocks:
        if block.num_elements == 0 or block.part_tag.size == 0:
            continue
        part_counts = Counter(block.part_tag.tolist())
        for part_id in sorted(part_counts):
            print(f"  partition {part_id}: {part_counts[part_id]} {label} elements")


def summarize(mesh_path: Path, *, one: int = 1) -> None:
    mesh = gmshparser.parse(mesh_path, one=one)
    print_header(mesh_path, mesh)
    print_physical_groups(mesh)
    print_element_inventory(mesh)
    print_counts_by_physical_group(mesh)
    print_partition_info(mesh)
    if one == 1:
        print("\nNode indices are 0-based (default one=1). Use one=0 for Gmsh/Matlab 1-based tags.")


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
    summarize(args.mesh, one=args.one)


if __name__ == "__main__":
    main()
