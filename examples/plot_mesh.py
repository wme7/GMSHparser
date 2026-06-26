"""Plot 2D or 3D Gmsh mesh connectivity from a .msh file."""

from __future__ import annotations

import argparse
from pathlib import Path

import gmshparser
import numpy as np
from gmshparser import Mesh

try:
    import matplotlib.pyplot as plt
    import matplotlib.tri as mtri
    from mpl_toolkits.mplot3d.art3d import Line3DCollection, Poly3DCollection
except ImportError as exc:  # pragma: no cover - optional dependency
    raise SystemExit(
        "plot_mesh.py requires matplotlib. Install with: uv pip install matplotlib"
    ) from exc


def _axis_labels(dim: int) -> tuple[str, ...]:
    return ("x", "y", "z")[:dim]


def _pad_coords(V: np.ndarray, dim: int) -> np.ndarray:
    out = np.zeros((V.shape[0], 3), dtype=float)
    out[:, :dim] = V[:, :dim]
    return out


def _plot_lines_2d(ax, V: np.ndarray, etov: np.ndarray, *, color: str = "C0") -> None:
    for edge in etov:
        pts = V[edge, :2]
        ax.plot(pts[:, 0], pts[:, 1], color=color, lw=0.8)


def _plot_surface_2d(ax, V: np.ndarray, mesh: Mesh) -> None:
    xy = V[:, :2]
    if mesh.SE_tri.num_elements:
        tri = mtri.Triangulation(xy[:, 0], xy[:, 1], mesh.SE_tri.EToV)
        ax.triplot(tri, color="0.35", lw=0.4)
    if mesh.SE_quad.num_elements:
        for quad in mesh.SE_quad.EToV:
            pts = xy[quad]
            closed = np.vstack([pts, pts[:1]])
            ax.plot(closed[:, 0], closed[:, 1], color="0.35", lw=0.4)


def _poly_collection(V: np.ndarray, etov: np.ndarray) -> Poly3DCollection:
    faces = [_pad_coords(V, 3)[nodes] for nodes in etov]
    coll = Poly3DCollection(
        faces,
        facecolors=(0.85, 0.88, 0.95, 0.35),
        edgecolors="0.35",
        linewidths=0.25,
    )
    return coll


def _wireframe_edges(etov: np.ndarray) -> list[tuple[int, int]]:
    """Return undirected edges for a batch of elements."""
    edge_set: set[tuple[int, int]] = set()
    for elem in etov:
        n = len(elem)
        for i in range(n):
            a = int(elem[i])
            b = int(elem[(i + 1) % n])
            edge_set.add((min(a, b), max(a, b)))
    return list(edge_set)


def _plot_wireframe_3d(ax, V: np.ndarray, etov: np.ndarray, *, color: str = "0.35") -> None:
    if etov.size == 0:
        return
    edges = _wireframe_edges(etov)
    segments = [_pad_coords(V, 3)[[a, b]] for a, b in edges]
    ax.add_collection3d(Line3DCollection(segments, colors=color, linewidths=0.35))


def _plot_boundary_3d(ax, V: np.ndarray, mesh: Mesh) -> None:
    if mesh.SE_tri.num_elements:
        ax.add_collection3d(_poly_collection(V, mesh.SE_tri.EToV))
    if mesh.SE_quad.num_elements:
        ax.add_collection3d(_poly_collection(V, mesh.SE_quad.EToV))


def _plot_volume_3d(ax, V: np.ndarray, mesh: Mesh) -> None:
    for block in (mesh.VE_tet, mesh.VE_hex, mesh.VE_prism):
        _plot_wireframe_3d(ax, V, block.EToV)


def _set_equal_aspect_2d(ax) -> None:
    ax.set_aspect("equal", adjustable="box")
    ax.autoscale_view()


def _set_equal_aspect_3d(ax, V: np.ndarray, dim: int) -> None:
    coords = V[:, :dim]
    mins = coords.min(axis=0)
    maxs = coords.max(axis=0)
    centers = 0.5 * (mins + maxs)
    radius = 0.5 * np.max(maxs - mins)
    for setter, center in zip((ax.set_xlim, ax.set_ylim, ax.set_zlim), centers):
        setter(center - radius, center + radius)


def plot_mesh(mesh_path: Path, mesh: Mesh, *, show_volume: bool, show_lines: bool) -> None:
    dim = mesh.info.phys_DIM
    V = mesh.V
    title = f"{mesh_path.name}  (Gmsh v{mesh.info.version}, {dim}D)"

    if dim == 2:
        fig, ax = plt.subplots(figsize=(6, 6))
        if show_lines and mesh.LE.num_elements:
            _plot_lines_2d(ax, V, mesh.LE.EToV, color="C3")
        _plot_surface_2d(ax, V, mesh)
        ax.set_xlabel("x")
        ax.set_ylabel("y")
        ax.set_title(title)
        _set_equal_aspect_2d(ax)
    else:
        fig = plt.figure(figsize=(7, 6))
        ax = fig.add_subplot(111, projection="3d")
        if show_volume:
            _plot_volume_3d(ax, V, mesh)
        else:
            _plot_boundary_3d(ax, V, mesh)
        if show_lines and mesh.LE.num_elements:
            _plot_wireframe_3d(ax, V, mesh.LE.EToV, color="C3")
        for axis, label in zip((ax.set_xlabel, ax.set_ylabel, ax.set_zlabel), _axis_labels(3)):
            axis(label)
        ax.set_title(title)
        _set_equal_aspect_3d(ax, V, 3)

    fig.tight_layout()
    plt.show()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mesh", type=Path, help="Path to a .msh file")
    parser.add_argument(
        "--volume",
        action="store_true",
        help="For 3D meshes, plot volume element wireframes instead of boundary surfaces",
    )
    parser.add_argument(
        "--lines",
        action="store_true",
        help="Overlay line (1D) elements, e.g. tagged boundary curves",
    )
    args = parser.parse_args()

    mesh = gmshparser.parse(args.mesh)
    show_volume = args.volume and mesh.info.phys_DIM == 3
    plot_mesh(args.mesh, mesh, show_volume=show_volume, show_lines=args.lines)


if __name__ == "__main__":
    main()
