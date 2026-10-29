"""Make the script's directory importable so tests reach the `lib` package."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))
