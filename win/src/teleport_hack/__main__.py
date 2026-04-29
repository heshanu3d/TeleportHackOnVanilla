"""Entry point: ``python -m teleport_hack`` or ``teleport-hack`` console script."""

from __future__ import annotations

import sys

from teleport_hack.presentation.app import run


def main() -> int:
    return run(sys.argv)


if __name__ == "__main__":
    sys.exit(main())
