#!/usr/bin/env python3.11

# Copyright (c) 2025
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import argparse
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional, Tuple


@dataclass
class EnvEntry:
    """Represents an environment variable entry with its value and associated comments."""
    key: str
    value: str
    comments: Optional[List[str]] = None

    def __post_init__(self):
        if self.comments is None:
            self.comments = []

    @property
    def prefix(self) -> str:
        """Get the prefix of the key (text before underscore or full key if no underscore)."""
        return self.key.split('_')[0] if '_' in self.key else self.key


class EnvFile:
    """Handles reading and parsing of .env files."""
    def __init__(self, file_path: Path):
        self.file_path = file_path
        self.entries: Dict[str, EnvEntry] = {}

    def read(self) -> None:
        """Read and parse the .env file."""
        current_comments: List[str] = []

        with open(self.file_path, 'r') as f:
            for line in f:
                line = line.strip()
                if not line:
                    current_comments = []
                    continue

                if line.startswith('#'):
                    current_comments.append(line)
                    continue

                if '=' in line:
                    key, value = line.split('=', 1)
                    key = key.strip()
                    value = value.strip()
                    self.entries[key] = EnvEntry(key, value, current_comments.copy())
                    current_comments = []

    def get_sorted_entries(self) -> List[EnvEntry]:
        """Return entries sorted by key."""
        return [self.entries[key] for key in sorted(self.entries.keys())]


class EnvComparator:
    """Compares two .env files."""
    def __init__(self, file1: Path, file2: Path):
        self.env1 = EnvFile(file1)
        self.env2 = EnvFile(file2)
        self.env1.read()
        self.env2.read()

    def compare(self) -> Tuple[List[str], List[str], Dict[str, Tuple[str, str]]]:
        """Compare two .env files and return the differences."""
        keys1 = set(self.env1.entries.keys())
        keys2 = set(self.env2.entries.keys())

        unique_to_file1 = sorted(keys1 - keys2)
        unique_to_file2 = sorted(keys2 - keys1)
        
        different_values = {}
        common_keys = keys1 & keys2
        for key in sorted(common_keys):
            if self.env1.entries[key].value != self.env2.entries[key].value:
                different_values[key] = (self.env1.entries[key].value, self.env2.entries[key].value)

        return unique_to_file1, unique_to_file2, different_values


class EnvFormatter:
    """Formats .env file content."""
    def __init__(self, file_path: Path):
        self.env_file = EnvFile(file_path)
        self.env_file.read()

    def format(self) -> str:
        """Format the .env file content."""
        entries = self.env_file.get_sorted_entries()
        
        # Group entries by prefix
        current_prefix = None
        formatted_lines = []

        for entry in entries:
            prefix = entry.prefix
            
            # Add blank line between different prefixes
            if current_prefix is not None and prefix != current_prefix:
                formatted_lines.append('')
            
            # Add comments
            if entry.comments:
                formatted_lines.extend(entry.comments)
            
            # Add the entry
            formatted_lines.append(f"{entry.key}={entry.value}")
            current_prefix = prefix

        return '\n'.join(formatted_lines)


def main():
    parser = argparse.ArgumentParser(description='Process .env files')
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('-c', '--compare', nargs=2, metavar=('FILE1', 'FILE2'),
                      help='Compare two .env files')
    group.add_argument('-f', '--format', metavar='FILE',
                      help='Format a .env file')

    args = parser.parse_args()

    try:
        if args.compare:
            file1, file2 = map(Path, args.compare)
            if not file1.exists() or not file2.exists():
                print("Error: One or both files do not exist", file=sys.stderr)
                sys.exit(1)

            comparator = EnvComparator(file1, file2)
            unique1, unique2, diff_values = comparator.compare()

            print(f"=== Keys unique to {file1} ===")
            for key in unique1:
                print(key)

            print(f"\n=== Keys unique to {file2} ===")
            for key in unique2:
                print(key)

            print("\n=== Keys with different values ===")
            for key, (val1, val2) in diff_values.items():
                print(f"{key}:")
                print(f"  {file1}: {val1}")
                print(f"  {file2}: {val2}")

        else:  # format mode
            file_path = Path(args.format)
            if not file_path.exists():
                print(f"Error: File {file_path} does not exist", file=sys.stderr)
                sys.exit(1)

            formatter = EnvFormatter(file_path)
            print(formatter.format())

    except Exception as e:
        print(f"Error: {str(e)}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()