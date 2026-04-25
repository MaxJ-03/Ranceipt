#!/usr/bin/env python
"""Quick test script for backend endpoints."""

import subprocess
import sys

# Test using subprocess to call curl
try:
    result = subprocess.run(
        ["C:\\Windows\\System32\\curl.exe", "http://127.0.0.1:8000/health"],
        capture_output=True,
        text=True,
        timeout=5,
    )
    print("Health check response:")
    print(f"Exit code: {result.returncode}")
    print(f"Output: {result.stdout}")
    if result.stderr:
        print(f"Errors: {result.stderr}")
except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)
