import hashlib
import json
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch
from zipfile import ZipFile

import pytest

from tools.source_bundle import record_artifact, source_datas, source_paths


@pytest.fixture
def source_tree(tmp_path):
    names = ["main.py", "LICENSE", "licenses/AGPL-3.0.txt", "requirements.txt",
             "assets/folimeld-supporter-maid.png", "tools/source_bundle.py"]
    for name in names:
        path = tmp_path / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(name.encode())
    (tmp_path / "SOURCE-MANIFEST.json").write_text(json.dumps({"files": dict.fromkeys(names)}))
    return tmp_path


def capture(root):
    with patch("tools.source_bundle.distributions", return_value=[
        SimpleNamespace(metadata={"Name": "Example"}, version="1.2.3")
    ]):
        data = source_datas(root, "test")
    return json.loads(Path(data[0][0]).read_text(encoding="utf-8"))


def test_archive_preserves_actual_inputs_and_environment(source_tree):
    (source_tree / "main.py").write_text("modified source", encoding="utf-8")
    record = capture(source_tree)
    archive = source_tree / "dist/source" / record["source_archive"]
    assert hashlib.sha256(archive.read_bytes()).hexdigest() == record["source_sha256"]
    with ZipFile(archive) as z:
        assert z.read("main.py") == b"modified source"
        assert z.read("assets/folimeld-supporter-maid.png")
        assert z.read("build-requirements.txt") == b"Example==1.2.3\n"
        assert json.loads(z.read("SOURCE-MANIFEST.json"))["files"] == record["files"]
    assert record["git_commit"] is None
    assert record["dependency_sources"].startswith("NOT INCLUDED")


def test_missing_required_source_fails(source_tree):
    (source_tree / "LICENSE").unlink()
    with pytest.raises(ValueError, match="Required source"):
        capture(source_tree)


def test_includes_linked_new_docs_but_excludes_unrelated_work(source_tree):
    (source_tree / ".git").mkdir()
    (source_tree / "docs").mkdir()
    (source_tree / "README.md").write_text("[Audit](docs/audit.md)")
    (source_tree / "docs/audit.md").write_text("Audit")
    (source_tree / "docs/unrelated.md").write_text("Unrelated work")
    tracked = list(json.loads((source_tree / "SOURCE-MANIFEST.json").read_text())["files"]) + ["README.md"]
    with patch("tools.source_bundle.git", side_effect=[
        "\0".join(tracked).encode(), b"docs/audit.md\0docs/unrelated.md\0"
    ]):
        paths = source_paths(source_tree)
    assert "docs/audit.md" in paths
    assert "docs/unrelated.md" not in paths


def test_rejects_old_binary_without_record(source_tree):
    with patch("PyInstaller.archive.readers.CArchiveReader", return_value=SimpleNamespace(toc={})), \
            pytest.raises(ValueError, match="no build source record"):
        record_artifact("old.exe", "old.exe", source_tree)


def test_association_verifies_archive_and_changed_sources(source_tree):
    record = capture(source_tree)
    exe = source_tree / "app.exe"
    exe.write_bytes(b"executable")
    reader = SimpleNamespace(toc={"licenses/Build-source.txt": None},
                             extract=lambda key: json.dumps(record).encode())
    with patch("PyInstaller.archive.readers.CArchiveReader", return_value=reader):
        path = record_artifact(exe, exe, source_tree / "dist/source", project_root=source_tree)
        assert json.loads(path.read_text())["artifact_sha256"] == hashlib.sha256(b"executable").hexdigest()
        assert json.loads(path.read_text())["source_archive"] == record["source_archive"]
        (source_tree / "main.py").write_bytes(b"changed during build")
        with pytest.raises(ValueError, match="Source changed"):
            record_artifact(exe, exe, source_tree / "dist/source", project_root=source_tree)
        archive = source_tree / "dist/source" / record["source_archive"]
        archive.write_bytes(b"tampered")
        with pytest.raises(ValueError, match="checksum mismatch"):
            record_artifact(exe, exe, source_tree / "dist/source")
