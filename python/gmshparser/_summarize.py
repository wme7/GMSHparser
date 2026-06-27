"""Human-readable mesh summaries for interactive use."""

from __future__ import annotations

import os
from collections import Counter
from collections.abc import Sequence
from typing import TYPE_CHECKING, Union

import numpy as np

from . import GEOMETRY_BLOCKS

if TYPE_CHECKING:
    from ._gmshparser import ElementBlock, Mesh

PathArg = Union[str, os.PathLike[str]]

AXES = "xyz"

GEOMETRY_LABELS = {
    "pnt": "points",
    "lin": "lines",
    "tri": "triangles",
    "quad": "quads",
    "tet": "tets",
    "hex": "hexes",
    "prism": "prisms",
}

PHYS_GROUP_BLOCKS: tuple[tuple[int, str], ...] = (
    (1, "lin"),
    (2, "tri"),
    (2, "quad"),
    (3, "tet"),
    (3, "hex"),
    (3, "prism"),
)

ELEMENT_PHYS_LABELS = {
    "lin": "line",
    "tri": "triangle",
    "quad": "quad",
    "tet": "tet",
    "hex": "hex",
    "prism": "prism",
}

VOLUME_BLOCKS = ("tet", "hex", "prism")


def _format_bbox(mesh: Mesh) -> str:
    dim = mesh.info.phys_DIM
    coords = mesh.V[:, :dim]
    parts = []
    for i in range(dim):
        lo, hi = coords[:, i].min(), coords[:, i].max()
        parts.append(f"{AXES[i]} ∈ [{lo:.4g}, {hi:.4g}]")
    return ", ".join(parts)


def _infer_physical_dimensions(mesh: Mesh) -> dict[int, int]:
    dims: dict[int, int] = {}
    for dim, name in PHYS_GROUP_BLOCKS:
        block = getattr(mesh.El, name)
        if block.num_elements == 0:
            continue
        for tag in np.unique(block.phys_tag):
            tag = int(tag)
            dims[tag] = max(dims.get(tag, 0), dim)
    return dims


def _count_by_phys_tag(block: ElementBlock) -> Counter[int]:
    if block.num_elements == 0:
        return Counter()
    tags, counts = np.unique(block.phys_tag, return_counts=True)
    return Counter(dict(zip(tags.astype(int), counts.astype(int))))


def _phys_name(mesh: Mesh, tag: int) -> str:
    return mesh.physical_names.get(tag, "?")


def _format_header(mesh: Mesh, path: PathArg | None) -> list[str]:
    info = mesh.info
    encoding = "ASCII" if info.format == 0 else "binary"
    lines: list[str] = []
    if path is not None:
        lines.append(f"Mesh: {os.fspath(path)}")
    lines.append(
        f"  Gmsh v{info.version}, {encoding}, {info.phys_DIM}D, order {info.element_order}"
    )
    lines.append(f"  Nodes: {info.num_nodes}")
    lines.append(f"  Bounding box: {_format_bbox(mesh)}")
    return lines


def _format_physical_groups(mesh: Mesh) -> list[str]:
    if not mesh.physical_names:
        return []
    lines = ["", "Physical groups:"]
    dims = _infer_physical_dimensions(mesh)
    for tag in sorted(mesh.physical_names):
        dim = dims.get(tag, "?")
        lines.append(f"  (dim {dim})  tag {tag:3d}  {mesh.physical_names[tag]!r}")
    return lines


def _format_element_inventory(mesh: Mesh) -> list[str]:
    present = [
        (GEOMETRY_LABELS[name], getattr(mesh.El, name))
        for name in GEOMETRY_BLOCKS
        if getattr(mesh.El, name).num_elements > 0
    ]
    if not present:
        return ["", "Elements: (none)"]
    lines = ["", "Elements:"]
    for label, block in present:
        nodes = block.nodes_per_element
        suffix = f"  ({nodes} nodes/elem)" if nodes else ""
        lines.append(f"  {label:10s}  {block.num_elements:6d}{suffix}")
    return lines


def _format_counts_by_physical_group(mesh: Mesh) -> list[str]:
    lines: list[str] = []
    for name in GEOMETRY_BLOCKS:
        if name == "pnt":
            continue
        block = getattr(mesh.El, name)
        counts = _count_by_phys_tag(block)
        if not counts:
            continue
        if not lines:
            lines.extend(["", "Elements by physical group:"])
        elem_label = ELEMENT_PHYS_LABELS[name]
        for tag in sorted(counts):
            label = _phys_name(mesh, tag)
            n = counts[tag]
            plural = f"{elem_label}{'s' if n != 1 else ''}"
            lines.append(f"  {label} (tag {tag}): {n} {plural}")
    return lines


def _format_partition_info(mesh: Mesh) -> list[str]:
    info = mesh.info
    if info.single_domain:
        return []
    lines = ["", f"Partitions: {info.num_partitions} (multi-domain mesh)"]
    for name in VOLUME_BLOCKS:
        block = getattr(mesh.El, name)
        if block.num_elements == 0 or block.part_tag.size == 0:
            continue
        part_counts = Counter(block.part_tag.tolist())
        for part_id in sorted(part_counts):
            lines.append(f"  partition {part_id}: {part_counts[part_id]} {name} elements")
    return lines


def _resolve_one(mesh: Mesh, one: int | None) -> int:
    if one is not None:
        return one
    return int(mesh.one)


def _format_indexing_note(one: int) -> list[str]:
    if one == 1:
        return [
            "",
            "Node indices are 0-based (one=1). Use one=0 for Gmsh/Matlab 1-based tags.",
        ]
    return ["", "Node indices preserve Gmsh/Matlab 1-based tags (one=0)."]


def repr_mesh(mesh: Mesh) -> str:
    """Compact summary for interactive display (``repr(mesh)``)."""
    info = mesh.info
    return (
        f"<Mesh {info.phys_DIM}D v{info.version:g} "
        f"order={info.element_order} nodes={info.num_nodes}>"
    )


def describe_mesh(
    mesh: Mesh,
    *,
    path: PathArg | None = None,
    one: int | None = None,
    header: bool = True,
    physical_groups: bool = True,
    elements: bool = True,
    elements_by_phys: bool = True,
    partitions: bool = True,
    indexing_note: bool = True,
) -> str:
    """Build a human-readable mesh summary."""
    sections: list[Sequence[str]] = []
    if header:
        sections.append(_format_header(mesh, path))
    if physical_groups:
        sections.append(_format_physical_groups(mesh))
    if elements:
        sections.append(_format_element_inventory(mesh))
    if elements_by_phys:
        sections.append(_format_counts_by_physical_group(mesh))
    if partitions:
        sections.append(_format_partition_info(mesh))
    if indexing_note:
        sections.append(_format_indexing_note(_resolve_one(mesh, one)))
    return "\n".join(line for section in sections for line in section)


def show_mesh(mesh: Mesh, **kwargs: object) -> None:
    """Print a human-readable mesh summary."""
    print(describe_mesh(mesh, **kwargs))  # type: ignore[arg-type]


def _mesh_describe(self: Mesh, **kwargs: object) -> str:
    return describe_mesh(self, **kwargs)  # type: ignore[arg-type]


def _mesh_show(self: Mesh, **kwargs: object) -> None:
    show_mesh(self, **kwargs)  # type: ignore[arg-type]


def _mesh_repr(self: Mesh) -> str:
    return repr_mesh(self)


def attach_mesh_display() -> None:
    from ._gmshparser import Mesh

    Mesh.describe = _mesh_describe  # type: ignore[method-assign]
    Mesh.show = _mesh_show  # type: ignore[method-assign]
    Mesh.__repr__ = _mesh_repr  # type: ignore[method-assign]
