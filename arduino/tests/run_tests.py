"""Compile and run the production firmware core and sketch with hardware doubles.

Requires Python 3 and a GNU-compatible C++ compiler. Outputs stay outside the repo.
These tests do not simulate SoftwareSerial interrupt latency or physical electronics.
"""
import os
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parent
compiler = os.environ.get("CXX", "g++")
with tempfile.TemporaryDirectory(prefix="smart-glove-tests-") as output:
    for source in ("core_test.cpp", "sketch_test.cpp"):
        binary = Path(output) / source.removesuffix(".cpp")
        subprocess.run([
            compiler, "-std=c++11", "-Wall", "-Wextra", "-Werror", "-g",
            "-fsanitize=address,undefined", "-I", str(root / "support"),
            str(root / source), "-o", str(binary),
        ], check=True)
        subprocess.run([str(binary)], check=True)
