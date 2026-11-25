"""Build and verify LF-only install/source QA archives from an immutable Git ref."""
import argparse
from datetime import datetime
import hashlib
import json
from pathlib import Path
import re
import subprocess
from zipfile import ZipFile, ZipInfo, ZIP_DEFLATED

ROOT = Path(__file__).resolve().parents[1]
VERSION = '1.3.20'
PLUGIN = 'redmine_project_percent_done'


def git(*args):
    return subprocess.check_output(['git', '-C', str(ROOT), *args]).decode('utf-8')


def digest(data):
    return hashlib.sha256(data).hexdigest().upper()


def committed_source(ref):
    records = subprocess.check_output(['git', '-C', str(ROOT), 'ls-tree', '-rz', ref]).split(b'\0')
    objects = []
    for record in filter(None, records):
        info, path = record.split(b'\t', 1)
        mode, kind, object_id = info.split()
        if kind != b'blob' or mode == b'120000':
            raise RuntimeError(f'Unsupported source object: {path!r}')
        objects.append((path.decode('utf-8'), object_id))
    content = subprocess.check_output(['git', '-C', str(ROOT), 'cat-file', '--batch'],
                                      input=b''.join(object_id + b'\n' for _, object_id in objects))
    source = {}
    offset = 0
    for path, _ in objects:
        header_end = content.index(b'\n', offset)
        _, kind, length = content[offset:header_end].split()
        if kind != b'blob':
            raise RuntimeError(f'Invalid object for {path}')
        offset = header_end + 1
        source[path] = content[offset:offset + int(length)]
        offset += int(length) + 1
    return source


def build_zip(path, files, metadata, manifest_path):
    """Hash all payload files, then reopen and verify exact inventory and bytes."""
    if path.exists():
        raise RuntimeError(f'Refusing to overwrite {path}')
    manifest = dict(metadata, files={name: digest(data) for name, data in sorted(files.items())})
    payload = dict(files)
    payload[manifest_path] = json.dumps(manifest, ensure_ascii=False, indent=2).encode('utf-8')
    with ZipFile(path, 'w', compression=ZIP_DEFLATED) as archive:
        for name, data in sorted(payload.items()):
            if name.startswith('/') or '..' in name.split('/'):
                raise RuntimeError(f'Unsafe ZIP name: {name}')
            entry = ZipInfo(name, (*map(int, metadata['date'].split('-')), 0, 0, 0))
            entry.create_system = 3
            entry.external_attr = 0o100644 << 16
            archive.writestr(entry, data, compress_type=ZIP_DEFLATED)
    with ZipFile(path) as archive:
        assert archive.testzip() is None
        assert set(archive.namelist()) == set(payload)
        assert len(archive.namelist()) == len(payload)
        loaded = json.loads(archive.read(manifest_path))
        for name, expected in loaded['files'].items():
            assert digest(archive.read(name)) == expected, name
    return {'filename': path.name, 'bytes': path.stat().st_size,
            'sha256': digest(path.read_bytes()), 'files': len(payload)}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--ref', required=True, help='Tested immutable QA tag or commit')
    parser.add_argument('--date', default='20261125', help='QA build date in Europe/Sofia, YYYYMMDD')
    parser.add_argument('--build-id', default='r2')
    parser.add_argument('--test-log', type=Path, default=ROOT / 'output/qa/1.3.20-r2/full.log')
    parser.add_argument('--benchmark', type=Path, default=ROOT / 'output/qa/1.3.20-r2/benchmark.txt')
    parser.add_argument('--out', type=Path, default=ROOT / 'release_packages')
    args = parser.parse_args()
    build_date = datetime.strptime(args.date, '%Y%m%d').date().isoformat()
    if not re.fullmatch(r'[A-Za-z0-9_-]+', args.build_id):
        raise RuntimeError('Invalid build identifier')
    exit_file = args.test_log.with_suffix('.exitcode')
    if exit_file.read_text(encoding='utf-8-sig').strip() != '0':
        raise RuntimeError('Complete test process did not exit successfully')
    log = args.test_log.read_text(encoding='utf-8-sig', errors='replace')
    matches = re.findall(r'(?m)^(\d+) runs, (\d+) assertions, (\d+) failures, (\d+) errors, (\d+) skips\s*$', log)
    if not matches or any(int(value) for value in matches[-1][2:]) or int(matches[-1][0]) < 165:
        raise RuntimeError('Missing successful complete Redmine 6.1.2 suite result')
    test_result = dict(zip(('runs', 'assertions', 'failures', 'errors', 'skips'), map(int, matches[-1])))
    source = committed_source(args.ref)
    # QA reports are repository evidence, not plugin/source package payload.
    source = {name: data for name, data in source.items() if not name.startswith('QA reports/')}
    if "PLUGIN_VERSION = '1.3.20'" not in source['lib/project_percent_done.rb'].decode('utf-8'):
        raise RuntimeError('Source version mismatch')
    for name, data in source.items():
        if name.startswith(('QA reports/', 'output/', 'tmp/', 'release_packages/')):
            raise RuntimeError(f'Unexpected generated/private source: {name}')
        if (ROOT / name).read_bytes() != data:
            raise RuntimeError(f'Workspace differs from tested Git source: {name}')
        if b'\0' not in data:
            data.decode('utf-8')
            if b'\r' in data:
                raise RuntimeError(f'Non-LF text file: {name}')
    source_hash = digest(json.dumps({name: digest(data) for name, data in sorted(source.items())},
                                   sort_keys=True).encode('utf-8'))
    metadata = {
        'plugin': PLUGIN, 'version': VERSION, 'algorithm': '1.2', 'public_contract': '1.0',
        'evidence_schema': '1.0', 'date': build_date, 'timezone': 'Europe/Sofia', 'build_id': args.build_id,
        'source_commit': git('rev-parse', args.ref + '^{commit}').strip(), 'source_ref': args.ref,
        'branch': git('branch', '--show-current').strip(), 'text_line_endings': 'LF',
        'source_state': 'committed Git snapshot', 'source_snapshot_sha256': source_hash,
        'source_worktree_dirty': bool(git('status', '--porcelain', '--untracked-files=no').strip()),
        'test_target': 'Redmine 6.1.2 / Ruby 3.3.11 / Windows / SQLite', 'tests': test_result,
        'test_exit_code': 0, 'test_log_sha256': digest(args.test_log.read_bytes()),
        'approval': 'Prepared for repeat QA; no new staging/production approval',
    }
    install = {f'{PLUGIN}/{name}': data for name, data in source.items()
               if name.startswith(('app/', 'assets/', 'config/', 'db/', 'lib/'))
               or name in ('init.rb', 'LICENSE')}
    install[f'{PLUGIN}/README.md'] = source['docs/INSTALL_1.3.20.md']
    for name in install:
        assert not re.search(r'(^|/)(\.github|AGENTS\.md|test|scripts|output|tmp)(/|$)', name)
    durations = re.findall(r'(?m)^Finished in .+$', log)
    summary = (f'PPD 1.3.20 {args.build_id} repeat-QA validation, {build_date} Europe/Sofia\n'
               'Redmine 6.1.2, Ruby 3.3.11, Windows/SQLite\n'
               'Command: scripts/run_redmine_plugin_tests.ps1; normal database preparation\n'
               + (durations[-1] if durations else '') + '\n'
               + ', '.join(f'{value} {name}' for name, value in test_result.items()) + '\n'
               'Known duplicate-constant warnings were non-fatal. Full process exit code: 0.\n'
               'No fresh MySQL/MariaDB, deployed UI, real SMTP/cron or production certification.\n')
    args.out.mkdir(parents=True, exist_ok=True)
    suffix = f'{args.date}-{args.build_id}'
    install_path = args.out / f'{PLUGIN}-{VERSION}-install-{suffix}.zip'
    install_info = build_zip(install_path, install, metadata, f'{PLUGIN}/QA_MANIFEST.json')
    source_payload = {f'{PLUGIN}/{name}': data for name, data in source.items()}
    source_path = args.out / f'{PLUGIN}-{VERSION}-source-{suffix}.zip'
    source_info = build_zip(source_path, source_payload, metadata, f'{PLUGIN}/QA_MANIFEST.json')
    bundle = {
        install_path.name: install_path.read_bytes(), source_path.name: source_path.read_bytes(),
        'QA_GUIDE_BG.md': source['docs/QA_GUIDE_1.3.20_BG.md'],
        'QA_RETEST_MATRIX.md': source['docs/QA_1.3.20.md'],
        'QA_TEST_RESULTS.txt': summary.encode('utf-8'),
        'QA_BENCHMARK.txt': args.benchmark.read_text(encoding='utf-8-sig').encode('utf-8'),
    }
    bundle_path = args.out / f'{PLUGIN}-{VERSION}-qa-bundle-{suffix}.zip'
    bundle_info = build_zip(bundle_path, bundle, dict(metadata, install=install_info, source=source_info),
                            'QA_MANIFEST.json')
    evidence = dict(bundle=bundle_info, install=install_info, source=source_info,
                    tests=test_result, source_snapshot_sha256=source_hash)
    evidence_path = args.test_log.parent / 'package-verification.json'
    evidence_path.parent.mkdir(parents=True, exist_ok=True)
    evidence_path.write_text(json.dumps(evidence, indent=2), encoding='utf-8')
    print(json.dumps(evidence, indent=2))


if __name__ == '__main__':
    main()
