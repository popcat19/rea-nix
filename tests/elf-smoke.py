# Purpose: Prove the packaged REA command performs an ELF layout inspection.
import json
import os
import pathlib
import subprocess
import sys
import tempfile

rea, source = sys.argv[1:]
with tempfile.TemporaryDirectory() as directory:
    binary = pathlib.Path(directory) / "fixture"
    subprocess.run(["cc", source, "-o", binary], check=True)
    result = subprocess.run(
        [f"{rea}/bin/rea", "inspect-binary-layout", str(binary)],
        capture_output=True,
        text=True,
        env={**os.environ, "REA_PWNTOOLS_PYTHON": f"{rea}/bin/python3"},
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr)
    assert "provider:" in result.stdout, result.stdout
    assert "id: pwntools-elf" in result.stdout, result.stdout
    assert "format: elf" in result.stdout, result.stdout
