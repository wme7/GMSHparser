"""Parse Gmsh .msh files (format v2.2 and v4.1)."""

from __future__ import annotations
from importlib.metadata import requires, version

import os
from typing import Any, Union

from numpy.typing import NDArray

from ._gmshparser import ElementBlock, Mesh, MeshInfo, ParseOptions
from ._gmshparser import parse as _parse
from ._gmshparser import parse_v2 as _parse_v2
from ._gmshparser import parse_v4 as _parse_v4

PathArg = Union[str, os.PathLike[str]]

__all__ = [
    "ElementBlock",
    "Mesh",
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
    """Return mesh arrays using legacy npz-style key names."""

    def block(prefix: str, block: ElementBlock, etov_key: str) -> dict[str, NDArray[Any]]:
        return {
            etov_key: block.EToV,
            f"{prefix}_phys_tag": block.phys_tag,
            f"{prefix}_geom_tag": block.geom_tag,
            f"{prefix}_part_tag": block.part_tag,
            f"{prefix}_Etype": block.Etype,
        }

    data: dict[str, NDArray[Any]] = {"V": mesh.V}
    data.update(block("PE", mesh.PE, "PEToV"))
    data.update(block("LE", mesh.LE, "LEToV"))
    data.update(block("SE_tri", mesh.SE_tri, "SE_tri_EToV"))
    data.update(block("SE_quad", mesh.SE_quad, "SE_quad_EToV"))
    data.update(block("VE_tet", mesh.VE_tet, "VE_tet_EToV"))
    data.update(block("VE_hex", mesh.VE_hex, "VE_hex_EToV"))
    data.update(block("VE_prism", mesh.VE_prism, "VE_prism_EToV"))
    return data
