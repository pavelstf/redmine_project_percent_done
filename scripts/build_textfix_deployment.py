"""Package the tested locale-only overlay without changing accepted r2 artifacts."""
from pathlib import Path
import hashlib
import json
import zipfile

ROOT = Path(__file__).resolve().parents[1]
PLUGIN = 'redmine_project_percent_done'
BUILD = 'r3-text'
OUT = ROOT/'release_packages'


def sha(data):
    return hashlib.sha256(data).hexdigest().upper()


def archive(path, payload):
    if path.exists():
        with zipfile.ZipFile(path) as old:
            assert set(old.namelist()) == set(payload)
            assert all(old.read(name) == data for name, data in payload.items())
    else:
        with zipfile.ZipFile(path, 'w') as output:
            for name, data in sorted(payload.items()):
                info = zipfile.ZipInfo(name, (2026, 11, 25, 0, 0, 0))
                info.external_attr = 0o100644 << 16
                output.writestr(info, data, compress_type=zipfile.ZIP_DEFLATED)
    with zipfile.ZipFile(path) as check:
        assert check.testzip() is None
    return {'filename': path.name, 'bytes': path.stat().st_size, 'sha256': sha(path.read_bytes())}


def main():
    log = ROOT/'output/production-1.3.20-r2/text-fix-full-verified.log'
    assert '165 runs, 1084 assertions, 0 failures, 0 errors, 0 skips' in log.read_text(encoding='utf-8-sig')
    source = OUT/f'{PLUGIN}-1.3.20-production-20261125-r2.zip'
    assert sha(source.read_bytes()) == 'FA3B218167DAEC4996486BB22D6D0F1D0B5FFC3CC0952DCFD2C1F1B923B60F67'
    with zipfile.ZipFile(source) as base:
        payload = {name: base.read(name) for name in base.namelist()}
    manifest_name = f'{PLUGIN}/QA_MANIFEST.json'
    manifest = json.loads(payload.pop(manifest_name))
    changed = []
    for locale in sorted((ROOT/'config/locales').glob('*.yml')):
        name = f'{PLUGIN}/config/locales/{locale.name}'
        current = locale.read_bytes()
        old = payload[name]
        expected = old.decode().replace(
            'Parent issues are excluded by default when they have child issues in the same project, to avoid double counting.',
            'Parent issues are excluded by default whenever they have child issues, regardless of which project the child issues belong to, to avoid double counting.').replace(
            'Parent задачите се изключват по подразбиране, когато имат подзадачи в същия проект, за да няма двойно броене.',
            'Родителските задачи се изключват по подразбиране, когато имат подзадачи, независимо към кой проект принадлежат подзадачите, за да няма двойно броене.').encode()
        assert current == expected and current != old and b'\r' not in current, name
        payload[name] = current
        changed.append(name)
    assert len(changed) == 50
    # Prevent packaging unrelated or untested local application changes.
    for name, data in payload.items():
        relative = name.removeprefix(PLUGIN + '/')
        if relative.startswith(('app/', 'lib/', 'db/', 'assets/', 'config/')) or relative == 'init.rb':
            assert (ROOT/relative).read_bytes() == data, relative
    manifest.update(build_id=BUILD, source_state='base QA ref plus tested locale-only working-tree overlay; not a new Git tag',
                    base_runtime_sha256=sha(source.read_bytes()), changed_runtime_files=changed,
                    tests={'runs':165,'assertions':1084,'failures':0,'errors':0,'skips':0},
                    test_log_sha256=sha(log.read_bytes()))
    manifest['files'] = {name: sha(data) for name, data in sorted(payload.items())}
    payload[manifest_name] = (json.dumps(manifest, ensure_ascii=False, indent=2)+'\n').encode()
    results = {}
    for target in ['staging', 'production']:
        runtime_name = f'{PLUGIN}-1.3.20-{target}-20261125-{BUILD}.zip'
        runtime_info = archive(OUT/runtime_name, payload)
        runtime = (OUT/runtime_name).read_bytes()
        scripts = {}
        for kind in ['install', 'rollback']:
            text = (ROOT/f'scripts/production/ppd-production-{kind}-1.3.20-r2.sh').read_text()
            text = text.replace('production operator p1', f'{target} text correction {BUILD}')
            text = text.replace('1.3.20-production-20261125-r2.zip', f'1.3.20-{target}-20261125-{BUILD}.zip')
            text = text.replace('EXPECTED_SHA=FA3B218167DAEC4996486BB22D6D0F1D0B5FFC3CC0952DCFD2C1F1B923B60F67', 'EXPECTED_SHA='+runtime_info['sha256'])
            text = text.replace('= 169409', '= '+str(len(runtime)))
            text = text.replace('1.3.20 r2', '1.3.20 '+BUILD)
            text = text.replace('# Verify every installed file against the original accepted QA manifest.', '# Verify the accepted r2 base plus the explicit locale-only overlay.')
            needle = "  abort 'Wrong QA ref' unless manifest['source_ref'] == 'qa-v1.3.20-r2'"
            text = text.replace(needle, needle + "\n  abort 'Wrong text build' unless manifest['build_id'] == 'r3-text'\n  abort 'Wrong locale overlay' unless manifest.fetch('changed_runtime_files').size == 50")
            text = text.replace('\nend\n\nroot =', '\n  puts \'TEXT_FIX_OK build=r3-text locales=50\'\nend\n\nroot =', 1)
            if target == 'staging':
                text = text.replace('/home/gcrbgcaa/rubyvenv/redmine612build/3.2', '/home/gcrbgcaa/rubyvenv/redminestaging/3.2')
                text = text.replace('/home/gcrbgcaa/redmine', '/home/gcrbgcaa/redminestaging')
                text = text.replace('redminestagingstaging', 'redminestaging')
                text = text.replace('production', 'staging').replace('Production', 'Staging')
                text = text.replace('RAILS_ENV=staging', 'RAILS_ENV=production').replace('Rails.env.staging?', 'Rails.env.production?')
            assert '< <(' not in text and 'SCRIPT_DIR' not in text and '/dev/fd' not in text
            filename = f'ppd-{target}-{kind}-1.3.20-{BUILD}.sh'
            destination = ROOT/f'scripts/{target}'/filename
            destination.write_text(text, encoding='utf-8', newline='\n')
            scripts[filename] = text.encode()
        venv = 'redminestaging' if target == 'staging' else 'redmine612build'
        app = 'redminestaging' if target == 'staging' else 'redmine'
        readme = f'''PPD 1.3.20 {BUILD} — {target}, 2026-11-25
Locale-only correction: exclude parents regardless of children's project.
Base: accepted r2; version/algorithm remain 1.3.20/1.2. Exactly 50 locale notes
and the package manifest differ. No application logic, schema or assets change.
Full local Redmine 6.1.2 suite: 165 runs, 1084 assertions, zero failures/errors/skips.
This new build has not been deployed. Install on staging and verify before production.
Root: /home/gcrbgcaa/{app}
Venv: /home/gcrbgcaa/rubyvenv/{venv}/3.2
Upload the entire handoff ZIP into the target plugins directory.
Runtime: {runtime_name}, {len(runtime)} bytes, SHA256 {runtime_info['sha256']}

clear
(
  set -eo pipefail
  cd /home/gcrbgcaa/{app}/plugins
  unzip -o {PLUGIN}-1.3.20-{target}-handoff-20261125-{BUILD}.zip
  sha256sum -c SHA256SUMS-{target}-{BUILD}
  bash /home/gcrbgcaa/{app}/plugins/ppd-{target}-install-1.3.20-{BUILD}.sh
)

The installer validates environment, checksum, recorded migration/schema,
then backs up DB/code/assets before replacement, verifies assets/runtime/text
build/settings/API/PB/PPH and touches tmp/restart.txt. No snapshots/backfill/email.
Require TEXT_FIX_OK build=r3-text locales=50, ASSETS_OK, AFTER_OK and final SUCCESS.
Validate corrected Calculation details note in English/Bulgarian, overview and
PB progress consistency. Existing snapshots retain their original values.

Rollback to the immediately preceding code/assets; DB/history retained:
clear
bash /home/gcrbgcaa/{app}/plugins/ppd-{target}-rollback-1.3.20-{BUILD}.sh
Backups remain under plugins; do not automatically restore SQL or run down migrations.
'''
        outer = {runtime_name:runtime, **scripts, f'README_{target.upper()}_{BUILD}.txt':readme.encode()}
        outer[f'SHA256SUMS-{target}-{BUILD}'] = ''.join(f'{sha(data)}  {name}\n' for name,data in outer.items()).encode()
        outer[f'MANIFEST-{target}-{BUILD}.json'] = (json.dumps({'build':BUILD,'target':target,'version':'1.3.20','algorithm':'1.2','state':'prepared, not deployed','runtime':runtime_info,'files':{n:sha(d) for n,d in outer.items()}},indent=2)+'\n').encode()
        results[target] = archive(OUT/f'{PLUGIN}-1.3.20-{target}-handoff-20261125-{BUILD}.zip', outer)
        results[target]['runtime'] = runtime_info
    assert (OUT/results['staging']['runtime']['filename']).read_bytes() == (OUT/results['production']['runtime']['filename']).read_bytes()
    evidence = ROOT/'output/textfix-r3'
    evidence.mkdir(exist_ok=True)
    (evidence/'packages.json').write_text(json.dumps(results, indent=2)+'\n')
    print(json.dumps(results, indent=2))


if __name__ == '__main__':
    main()
