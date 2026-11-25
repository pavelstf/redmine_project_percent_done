"""Linux-only sandbox tests: real shell/files/ZIP/tar, mocked host/Rails/DB commands.

Never connects to a server or boots Redmine. Runs beneath a fresh /tmp fixture.
"""
from contextlib import contextmanager
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[2]
PLUGIN = 'redmine_project_percent_done'
INSTALL = 'ppd-staging-install-1.3.20-r2.sh'
ROLLBACK = 'ppd-staging-rollback-1.3.20-r2.sh'
HELPER = 'ppd-staging-check-1.3.20-r2.rb'
ZIP = f'{PLUGIN}-1.3.20-staging-20261125-r2.zip'
OPERATOR_ARCHIVE = None
TARGET = 'staging'
EXISTING_VERSION = '1.3.19'
ROOT_NAME = 'redminestaging'
VENV_NAME = 'redminestaging'

MOCK = r'''#!/usr/bin/env python3
import json, os, re, sys, subprocess
from pathlib import Path
from zipfile import ZipFile
name = Path(sys.argv[0]).name
args = sys.argv[1:]
root = Path(os.environ['PPD_FIXTURE_ROOT'])
failure = os.environ.get('PPD_FIXTURE_FAIL', '')
def version():
    text = (root/'plugins/redmine_project_percent_done/lib/project_percent_done.rb').read_text()
    return re.search(r"PLUGIN_VERSION = '([^']+)'", text).group(1)
def event(value):
    with Path(os.environ['PPD_FIXTURE_EVENTS']).open('a') as f:
        f.write(json.dumps(value)+'\n')
if name == 'clear':
    sys.exit(0)
if name == 'id':
    assert args == ['-un']; print('gcrbgcaa'); sys.exit(0)
if name == 'ruby':
    if args == ['--version']:
        print('ruby 3.2 fixture'); sys.exit(0)
    assert args[:2] == ['-rjson', '-e'], args
    print(json.loads(Path(args[-1]).read_text())['version']); sys.exit(0)
if name == 'unzip':
    assert args[0] == '-q' and args[2] == '-d', args
    with ZipFile(args[1]) as z:
        assert all(n.startswith('redmine_project_percent_done/') and '..' not in n.split('/') for n in z.namelist())
        z.extractall(args[3])
    sys.exit(0)
if name == 'mariadb-dump':
    raise AssertionError('Mock Rails handles DB fixture; no actual dump is allowed')
assert name == 'bundle', name
event({'args':args, 'mode':os.environ.get('PPD_DEPLOY_MODE', os.environ.get('PPD_STAGE_MODE'))})
if args == ['check']:
    print("The Gemfile's dependencies are satisfied"); sys.exit(0)
if args[:3] == ['exec', 'rake', 'redmine:plugins:migrate']:
    assert args[3:] == ['NAME=redmine_project_percent_done'], args
    assert os.environ['RAILS_ENV'] == 'production'
    sys.exit(31 if failure == 'migrate' else 0)
assert args[:3] == ['exec','rails','runner'], args
check = Path(args[3])
assert check.is_file(), 'Ruby verifier missing after cwd change'
assert root/'plugins' not in check.parents, 'Verifier must be outside plugins'
assert "mode = ENV.fetch('PPD_STAGE_MODE')" in check.read_text() or "mode = ENV.fetch('PPD_DEPLOY_MODE')" in check.read_text()
assert os.environ['RAILS_ENV'] == 'production'
mode = os.environ.get('PPD_DEPLOY_MODE', os.environ.get('PPD_STAGE_MODE'))
if mode == 'before':
    assert version() == '1.3.19'
    if failure == 'before':
        print('fixture preflight/DB backup failure', file=sys.stderr); sys.exit(21)
    Path(os.environ['PPD_BASELINE']).write_text(json.dumps({'version':'1.3.19'}))
    Path(os.environ['PPD_DB_BACKUP']).write_text('fixture transaction-consistent SQL backup\n')
    print('BEFORE_OK version=1.3.19 algorithm=1.1 projects=1')
elif mode == 'assets':
    assert version() == '1.3.20'
    if failure == 'assets':
        print('fixture asset refresh failure', file=sys.stderr); sys.exit(33)
    module = check.read_text().split('# ASSET_REFRESH_BEGIN\n')[1].split('# ASSET_REFRESH_END')[0]
    code = "require 'fileutils'\nrequire 'digest'\n" + module
    code += '\nputs "ASSETS_OK verified_copies=#{PpdDeploymentAssets.refresh(' + json.dumps(str(root)) + ')}"\n'
    result = subprocess.run(['/usr/bin/ruby', '-e', code])
    sys.exit(result.returncode)
elif mode == 'after':
    assert version() == '1.3.20'
    if failure == 'after':
        print('fixture after verification failure', file=sys.stderr); sys.exit(32)
    print('AFTER_OK version=1.3.20 algorithm=1.2 settings_preserved=true')
elif mode == 'rollback':
    assert version() == os.environ['PPD_ROLLBACK_VERSION'] == '1.3.19'
    print('ROLLBACK_VERSION_OK=1.3.19')
else:
    raise AssertionError(mode)
'''


def tree(path):
    return {str(file.relative_to(path)): hashlib.sha256(file.read_bytes()).hexdigest()
            for file in path.rglob('*') if file.is_file()}


@contextmanager
def fixture(legacy=False):
    with tempfile.TemporaryDirectory(prefix='ppd-operator-fixture-') as temp:
        base = Path(temp)
        root = base / ROOT_NAME
        venv = base / f'rubyvenv/{VENV_NAME}/3.2'
        bin_dir = base / 'bin'
        for path in [root/'plugins', root/'tmp', root/'log', venv/'bin', bin_dir, base/'home', base/'work']:
            path.mkdir(parents=True, exist_ok=True)
        (root/'Gemfile').write_text('# fixture\n')
        (root/'log/production.log').write_text('fixture previous log\n')
        old = root/'plugins'/PLUGIN
        (old/'lib').mkdir(parents=True)
        (old/'init.rb').write_text('# fixture old init\n')
        (old/'lib/project_percent_done.rb').write_text(f"module ProjectPercentDone\n  PLUGIN_VERSION = '{EXISTING_VERSION}'\nend\n")
        for public in ['public/plugin_assets', 'public/assets/plugin_assets']:
            asset = root/public/PLUGIN/'stylesheets'
            asset.mkdir(parents=True)
            (asset/'project_percent_done.css').write_text('fixture old CSS\n')
            if 'public/assets' in public:
                (asset/'project_percent_done-deadbeef.css').write_text('fixture old fingerprint\n')
        (base/'mock.py').write_text(MOCK.replace('1.3.19', EXISTING_VERSION))
        (base/'mock.py').chmod(0o755)
        for name in ['clear', 'id', 'bundle', 'unzip', 'mariadb-dump']:
            (bin_dir/name).symlink_to(base/'mock.py')
        (venv/'bin/ruby').symlink_to(base/'mock.py')
        activation = ("printf 'nil versions fixture warning\\n' >&2\nfalse\n"
                      f"export PATH='{venv}/bin:{bin_dir}':\"$PATH\"\n"
                      f"cd '{base}/home'\nreturn 0\n")
        (venv/'bin/activate').write_text(activation)
        if legacy:
            archive_path = ROOT/'release_packages'/f'{PLUGIN}-1.3.20-staging-handoff-20261125-r2-op2.zip'
            with ZipFile(archive_path) as archive:
                texts = {name: archive.read(name).decode() for name in [INSTALL, ROLLBACK, HELPER]}
        elif OPERATOR_ARCHIVE:
            with ZipFile(OPERATOR_ARCHIVE) as archive:
                assert HELPER not in archive.namelist(), 'Current operator should not require external helper'
                texts = {name: archive.read(name).decode() for name in [INSTALL, ROLLBACK]}
        else:
            texts = {name: (ROOT/f'scripts/{TARGET}'/name).read_text() for name in [INSTALL, ROLLBACK]}
        for name, text in texts.items():
            text = text.replace(f'/home/gcrbgcaa/{ROOT_NAME}', str(root))
            text = text.replace(f'/home/gcrbgcaa/rubyvenv/{VENV_NAME}/3.2', str(venv))
            text = text.replace(f'/tmp/ppd-{TARGET}-1.3.20-r2.', str(base/f'work/ppd-{TARGET}-1.3.20-r2.'))
            text = text.replace(f'/tmp/ppd-{TARGET}-rollback.', str(base/f'work/ppd-{TARGET}-rollback.'))
            (root/'plugins'/name).write_text(text)
        shutil.copyfile(ROOT/'release_packages'/ZIP, root/'plugins'/ZIP)
        env = dict(os.environ, PPD_FIXTURE_ROOT=str(root), PPD_FIXTURE_EVENTS=str(base/'events.jsonl'))
        env['PATH'] = f'{bin_dir}:' + env['PATH']
        state = {'base':base, 'root':root, 'venv':venv, 'env':env,
                 'old_code':tree(old), 'old_assets':tree(root/'public')}
        yield state


def run(state, name=None, absolute=False, args=(), failure=''):
    name = name or INSTALL
    env = dict(state['env'], PPD_FIXTURE_FAIL=failure)
    cwd = state['base']/'home' if absolute else state['root']/'plugins'
    script = str(state['root']/'plugins'/name) if absolute else './'+name
    return subprocess.run(['bash', script, *args], cwd=cwd, env=env, capture_output=True, text=True)


def preserved(state):
    assert tree(state['root']/'plugins'/PLUGIN) == state['old_code']
    assert tree(state['root']/'public') == state['old_assets']


def restored(state, absolute=False):
    result = run(state, ROLLBACK, absolute=absolute)
    assert result.returncode == 0, result.stdout + result.stderr
    assert 'SUCCESS:' in result.stdout
    preserved(state)
    return result


def main():
    global OPERATOR_ARCHIVE, TARGET, ROOT_NAME, VENV_NAME, INSTALL, ROLLBACK, HELPER, ZIP, EXISTING_VERSION
    parser = argparse.ArgumentParser()
    parser.add_argument('--archive', type=Path)
    parser.add_argument('--target', choices=['staging','production'], default='staging')
    parser.add_argument('--build-id', default='r2')
    parser.add_argument('--existing-version', choices=['1.3.19', '1.3.20'], default='1.3.19')
    args = parser.parse_args()
    EXISTING_VERSION = args.existing_version
    OPERATOR_ARCHIVE = args.archive
    TARGET = args.target
    if TARGET == 'production':
        ROOT_NAME, VENV_NAME = 'redmine', 'redmine612build'
        INSTALL = 'ppd-production-install-1.3.20-r2.sh'
        ROLLBACK = 'ppd-production-rollback-1.3.20-r2.sh'
        HELPER = 'ppd-production-check-1.3.20-r2.rb'
        ZIP = f'{PLUGIN}-1.3.20-production-20261125-r2.zip'
    assert os.name == 'posix', 'Run inside Linux/WSL; never run against a host installation'
    print(f'Operator under test: {OPERATOR_ARCHIVE or "workspace scripts"}')
    if args.build_id != 'r2':
        INSTALL = f'ppd-{TARGET}-install-1.3.20-{args.build_id}.sh'
        ROLLBACK = f'ppd-{TARGET}-rollback-1.3.20-{args.build_id}.sh'
        ZIP = f'{PLUGIN}-1.3.20-{TARGET}-20261125-{args.build_id}.zip'
    if TARGET == 'staging' and args.build_id == 'r2':
      with fixture(legacy=True) as state:
        assert (state['root']/'plugins'/HELPER).is_file()
        result = run(state, args=('--preflight-only',))
        assert result.returncode != 0 and 'line=29' in result.stderr, result
        assert 'VENV_ACTIVATED' in result.stdout
        preserved(state)
        print('PASS 1: op2 reproduces exact line-29 failure despite helper being present')
    with fixture() as state:
        assert not (state['root']/'plugins'/HELPER).exists()
        result = run(state, args=('--preflight-only',))
        assert result.returncode == 0 and f'SUCCESS: {TARGET} preflight' in result.stdout, result
        preserved(state)
        assert not list((state['root']/'plugins').glob('*backup*'))
        events = [json.loads(line) for line in (state['base']/'events.jsonl').read_text().splitlines()]
        assert [event['args'] for event in events] == [['check']]
        print('PASS 2: relative preflight after activation changes cwd; no helper/DB/deploy required')
    for number, absolute in [(3, False), (4, True)]:
        with fixture() as state:
            result = run(state, absolute=absolute)
            assert result.returncode == 0 and 'SUCCESS:' in result.stdout, result.stdout+result.stderr
            assert (state['root']/'tmp/restart.txt').exists()
            backup = Path((state['root']/'plugins'/f'{PLUGIN}-{TARGET}-last-backup.txt').read_text().strip())
            assert backup.is_file() and backup.with_name(backup.name+'.version').read_text().strip() == EXISTING_VERSION
            restored(state, absolute=absolute)
            print(f'PASS {number}: full {"absolute/home" if absolute else "relative/plugins"} install, backups/assets/migrations/verification and rollback')
    with fixture() as state:
        with (state['root']/'plugins'/ZIP).open('ab') as file:
            file.write(b'corrupt')
        result = run(state)
        assert result.returncode != 0 and 'phase=package checksum' in result.stderr
        preserved(state)
        assert not list((state['root']/'plugins').glob('*backup*'))
        print('PASS 5: checksum failure stops before backups or replacement')
    with fixture() as state:
        result = run(state, failure='before')
        assert result.returncode != 0 and 'phase=baseline and database backup' in result.stderr
        preserved(state)
        assert not (state['root']/'plugins'/f'{PLUGIN}-{TARGET}-last-backup.txt').exists()
        print('PASS 6: simulated baseline/DB failure preserves original installation')
    for number, failure in [(7, 'migrate'), (8, 'after')]:
        with fixture() as state:
            result = run(state, failure=failure)
            assert result.returncode != 0, result
            restored(state)
            print(f'PASS {number}: simulated {failure} failure keeps backups and permits complete code/asset rollback')
    with fixture() as state:
        (state['venv']/'bin/activate').write_text('return 7\n')
        result = run(state)
        assert result.returncode == 7 and 'activation failed, exit=7' in result.stderr
        preserved(state)
        print('PASS 9: real activation failure remains fatal')
    if TARGET == 'production' or args.build_id != 'r2':
        with fixture() as state:
            result = run(state, failure='assets')
            assert result.returncode != 0 and 'phase=plugin asset refresh' in result.stderr
            restored(state)
            print('PASS: asset-mode failure stops and rollback restores code/assets')
        with fixture() as state:
            alias = state['base']/'physical-other-root'
            state['root'].rename(alias)
            state['root'].symlink_to(alias, target_is_directory=True)
            result = run(state, absolute=True)
            assert result.returncode != 0 and f'phase={TARGET} root and user' in result.stderr
            preserved(state)
            assert not (state['base']/'events.jsonl').exists()
            print('PASS: wrong physical root refused before bundle, backup or deployment')
    count = 10 if TARGET == 'production' or args.build_id != 'r2' else 9
    print(f'{count} workflow checks passed. Rails/DB execution was mocked; no remote commands were run.')


if __name__ == '__main__':
    main()
