from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parents[1]
MESH_DIR = REPO_ROOT / "meshes"
REFERENCE_DIR = REPO_ROOT / "tests" / "reference"


@pytest.fixture(scope="session")
def mesh_dir() -> Path:
    return MESH_DIR


def all_mesh_files(mesh_dir: Path) -> list[Path]:
    return sorted(mesh_dir.glob("*.msh"))


def mesh_stems(mesh_dir: Path) -> list[str]:
    return sorted({path.stem.rsplit("_v", 1)[0] for path in mesh_dir.glob("*_v2.msh")})


def reference_mesh_paths() -> list[Path]:
    """Meshes that have a Matlab-exported .mat file under tests/reference/."""
    paths: list[Path] = []
    for ref_path in sorted(REFERENCE_DIR.glob("*.mat")):
        mesh_path = MESH_DIR / ref_path.name.replace(".mat", ".msh")
        if mesh_path.is_file():
            paths.append(mesh_path)
    return paths
