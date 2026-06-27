"""Parse Gmsh .msh files (format v2.2 and v4.1)."""

from __future__ import annotations
from importlib.metadata import requires, version

import os
from typing import Any, Union

from numpy.typing import NDArray

from ._gmshparser import ElementBlock, Mesh, MeshElements, MeshInfo, ParseOptions
from ._gmshparser import parse as _parse
from ._gmshparser import parse_v2 as _parse_v2
from ._gmshparser import parse_v4 as _parse_v4

PathArg = Union[str, os.PathLike[str]]

GEOMETRY_BLOCKS = ("pnt", "lin", "tri", "quad", "tet", "hex", "prism")

__all__ = [
    "ElementBlock",
    "GEOMETRY_BLOCKS",
    "Mesh",
    "MeshElements",
    "MeshInfo",
    "ParseOptions",
    "as_dict",
    "parse",
    "parse_v2",
    "parse_v4",
]

__version__ = version("gmshparser")
__requires__ = requires("gmshparser")

def _as_str(path: PathArg) -> str:
    return os.fspath(path)


def _resolve_options(
    *,
    one: int,
    debug: bool,
    options: ParseOptions | None,
) -> ParseOptions:
    if options is not None:
        return options
    opts = ParseOptions()
    opts.one = one
    opts.debug = debug
    return opts


def parse_v2(
    path: PathArg,
    *,
    one: int = 1,
    debug: bool = False,
    options: ParseOptions | None = None,
) -> Mesh:
    opts = _resolve_options(one=one, debug=debug, options=options)
    return _parse_v2(_as_str(path), opts)


def parse_v4(
    path: PathArg,
    *,
    one: int = 1,
    debug: bool = False,
    options: ParseOptions | None = None,
) -> Mesh:
    opts = _resolve_options(one=one, debug=debug, options=options)
    return _parse_v4(_as_str(path), opts)


def parse(
    path: PathArg,
    *,
    one: int = 1,
    debug: bool = False,
    options: ParseOptions | None = None,
) -> Mesh:
    opts = _resolve_options(one=one, debug=debug, options=options)
    return _parse(_as_str(path), opts)


def as_dict(mesh: Mesh) -> dict[str, NDArray[Any]]:
    """Return mesh arrays as a flat dictionary of NumPy arrays."""

    def block(name: str, elem: ElementBlock) -> dict[str, NDArray[Any]]:
        return {
            f"{name}_EToV": elem.EToV,
            f"{name}_phys_tag": elem.phys_tag,
            f"{name}_geom_tag": elem.geom_tag,
            f"{name}_part_tag": elem.part_tag,
            f"{name}_Etype": elem.Etype,
        }

    data: dict[str, NDArray[Any]] = {"V": mesh.V}
    for name in GEOMETRY_BLOCKS:
        data.update(block(name, getattr(mesh.El, name)))
    return data


from ._summarize import attach_mesh_display

attach_mesh_display()
