"""Helpers for comparing gmshparser output with Matlab reference files."""

from __future__ import annotations

from pathlib import Path
from typing import Any

import numpy as np
from numpy.typing import NDArray
from scipy.io import loadmat

from gmshparser import Mesh, as_dict

REFERENCE_SUFFIX = ".mat"


def _matlab_scalar_to_str(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, bytes):
        return value.decode()
    if isinstance(value, str):
        return value.strip()
    if isinstance(value, np.ndarray):
        if value.dtype.kind in {"U", "S"}:
            return str(value.reshape(())).strip()
        if value.size == 1:
            return _matlab_scalar_to_str(value.item())
    return str(value).strip()


def _matlab_to_str_array(arr: NDArray[Any]) -> NDArray[Any]:
    return np.vectorize(_matlab_scalar_to_str)(np.asarray(arr)).reshape(-1)


def _is_matlab_opaque(arr: NDArray[Any]) -> bool:
    names = arr.dtype.names
    return names is not None and {"_TypeSystem", "_Class", "_ObjectMetadata"}.issubset(names)


def pad_vertices(V: NDArray[np.floating[Any]], phys_dim: int) -> NDArray[np.float64]:
    out = np.zeros((V.shape[0], 3), dtype=np.float64)
    out[:, :phys_dim] = V[:, :phys_dim]
    return out


def mesh_to_reference_dict(mesh: Mesh) -> dict[str, NDArray[Any]]:
    data = as_dict(mesh)
    data["V"] = pad_vertices(mesh.V, mesh.info.phys_DIM)
    data["info_version"] = np.array([mesh.info.version])
    data["info_format"] = np.array([mesh.info.format])
    data["info_endian"] = np.array([mesh.info.endian])
    data["info_phys_DIM"] = np.array([mesh.info.phys_DIM])
    data["info_num_nodes"] = np.array([mesh.info.num_nodes])
    data["info_single_domain"] = np.array([float(mesh.info.single_domain)])
    data["info_num_partitions"] = np.array([mesh.info.num_partitions])
    tags = np.array(sorted(mesh.physical_names), dtype=np.int64)
    names = np.array([mesh.physical_names[tag] for tag in tags])
    data["physical_name_tags"] = tags
    data["physical_name_values"] = names
    return data


def load_reference(path: Path) -> dict[str, NDArray[Any]]:
    raw = loadmat(path, squeeze_me=False, struct_as_record=False)
    data: dict[str, NDArray[Any]] = {}
    for key, value in raw.items():
        if key.startswith("__"):
            continue
        arr = np.asarray(value)
        if _is_matlab_opaque(arr):
            raise ValueError(
                f"{key} in {path.name}: MATLAB string/object type is not readable by scipy; "
                "re-export references with cellstr via Matlab/export_test_references.m"
            )
        if arr.dtype.kind == "O":
            data[key] = _matlab_to_str_array(arr)
        elif arr.dtype.kind in {"U", "S"}:
            data[key] = arr.astype(str)
        else:
            data[key] = arr
    return data


def _normalize_array(arr: NDArray[Any]) -> NDArray[Any]:
    if arr.dtype.kind == "O":
        return _matlab_to_str_array(arr)
    if arr.dtype.kind in {"U", "S"}:
        return np.vectorize(lambda value: str(value).strip())(np.asarray(arr, dtype=str))
    if arr.size == 1:
        return np.asarray(arr).reshape(())
    return np.squeeze(arr)


def assert_arrays_equal(
    actual: NDArray[Any],
    expected: NDArray[Any],
    *,
    label: str,
) -> None:
    actual_norm = _normalize_array(actual)
    expected_norm = _normalize_array(expected)

    if actual_norm.dtype.kind in {"U", "S", "O"} or expected_norm.dtype.kind in {"U", "S", "O"}:
        assert np.array_equal(actual_norm, expected_norm), label
        return

    if actual_norm.size == 0 and expected_norm.size == 0:
        return

    if actual_norm.shape != expected_norm.shape:
        raise AssertionError(f"{label}: shape {actual_norm.shape} != {expected_norm.shape}")

    if np.issubdtype(actual_norm.dtype, np.floating) or np.issubdtype(expected_norm.dtype, np.floating):
        np.testing.assert_allclose(
            actual_norm.astype(np.float64),
            expected_norm.astype(np.float64),
            rtol=0.0,
            atol=1e-12,
            err_msg=label,
        )
    else:
        np.testing.assert_array_equal(actual_norm, expected_norm, err_msg=label)


def compare_mesh_to_reference(mesh: Mesh, reference: dict[str, NDArray[Any]]) -> None:
    actual = mesh_to_reference_dict(mesh)

    for key, expected in reference.items():
        if key not in actual:
            raise AssertionError(f"Missing key in parser output: {key}")
        assert_arrays_equal(actual[key], expected, label=key)

    extra = set(actual) - set(reference)
    if extra:
        raise AssertionError(f"Unexpected extra keys in parser output: {sorted(extra)}")
