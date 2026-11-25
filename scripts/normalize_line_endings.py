"""Normalize Git-visible UTF-8 source text to LF; leave ignored/binary inputs alone."""
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parents[1]
paths = subprocess.check_output(
    ['git', '-C', str(root), 'ls-files', '--cached', '--others', '--exclude-standard', '-z']
).decode('utf-8').split('\0')
changed = []
checked = 0
for name in sorted(set(paths) - {''}):
    if name.startswith(('QA reports/', 'output/', 'tmp/', 'release_packages/')):
        continue
    path = root / name
    if path.is_symlink() or not path.is_file():
        raise RuntimeError(f'Unexpected source path: {name}')
    before = path.read_bytes()
    if b'\0' in before:
        continue
    try:
        before.decode('utf-8')
    except UnicodeDecodeError:
        continue
    checked += 1
    normalized = before.replace(b'\r\n', b'\n').replace(b'\r', b'\n')
    if normalized != before:
        path.write_bytes(normalized)
        assert path.read_bytes() == normalized
        changed.append(name)
print(f'Checked {checked} source text files; normalized {len(changed)} to LF')
for name in changed:
    print(name)
