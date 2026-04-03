#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Fixes a recurring TEI typo in <listWit>: text that should be inside <witness>
is accidentally placed after the closing tag, like:
    </witness>thèse ... , p X.
instead of:
    thèse ... , p X.</witness>

This script moves any non-whitespace plain text that appears immediately after
</witness> (and before the next <witness> or </listWit>) back inside the witness.

Usage:
  python fix_witness_closing.py input.xml output.xml

If output.xml is omitted, it writes to: input.fixed.xml
"""

import re
import sys
from pathlib import Path


def fix_witness_closing(xml_text: str) -> tuple[str, int]:
    """
    Move stray text between </witness> and the next <witness> or </listWit>
    back before </witness>.

    Example:
      </witness>thèse ... p X. <witness ...>
    becomes:
      thèse ... p X.</witness> <witness ...>

    Returns: (fixed_xml, number_of_fixes)
    """
    pattern = re.compile(
        r"</witness>(\s*[^<]*\S[^<]*?)(?=\s*<(?:witness\b|/listWit>))",
        flags=re.DOTALL,
    )
    fixed, n = pattern.subn(r"\1</witness>", xml_text)
    return fixed, n


def main() -> None:
    if len(sys.argv) < 2:
        print("Usage: python fix_witness_closing.py input.xml [output.xml]")
        sys.exit(1)

    input_path = Path(sys.argv[1])
    output_path = Path(sys.argv[2]) if len(sys.argv) >= 3 else input_path.with_suffix(".fixed.xml")

    xml_text = input_path.read_text(encoding="utf-8", errors="replace")
    fixed_text, nfix = fix_witness_closing(xml_text)

    output_path.write_text(fixed_text, encoding="utf-8")
    print(f"OK ✅ witness fixes: {nfix}")
    print(f"Wrote: {output_path}")


if __name__ == "__main__":
    main()
