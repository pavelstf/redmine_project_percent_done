# Release Checklist

## Before Release

- Update the plugin version in `init.rb`.
- Update `CHANGELOG.md`.
- Run syntax checks.
- Run plugin tests inside a Redmine test environment.
- Confirm that `master-prompt.md`, zip archives, logs, temporary files, and staging data are not committed.

## Static Checks

From the plugin root:

```bash
ruby -c init.rb
find lib app test -name "*.rb" -print0 | xargs -0 -n1 ruby -c
ruby -e 'require "yaml"; Dir["config/locales/*.yml"].each { |f| YAML.load_file(f) }'
ruby -rerb -e 'Dir["app/views/**/*.erb"].each { |f| RubyVM::InstructionSequence.compile(ERB.new(File.read(f)).src) }'
ruby -c app/views/project_percent_done/show.api.rsb
```

## Package

Create an archive whose root directory is:

```text
redmine_project_percent_done
```

Do not include local files such as:

- `master-prompt.md`
- `*.zip`
- `.bundle/`
- `vendor/bundle/`
- local Redmine checkouts
- logs or temporary files

## GCR 1.1.1 Staging Package

Version `1.1.1` is a patch release for Administration settings help UI only.
It does not change calculation behavior, REST output, Public API V1, or the
Risk Monitor integration contract.

Staging package:

```text
redmine_project_percent_done-1.1.1-staging-20260710.zip
```

SHA-256:

```text
A5DEFBC04FE6C5FBABB42661B80D21B33702147100EFB9C9C97E3E5315466388
```

Production package:

```text
redmine_project_percent_done-1.1.1-production-20260710.zip
```

The Production package is a byte-for-byte copy of the accepted Staging package
and has the same SHA-256. Production deployment instructions are documented in
`docs/PRODUCTION_RUNBOOK_1.1.1.md`.

Because `1.1.1` adds `assets/stylesheets/project_percent_done.css`, deployment
runbooks must include guarded plugin asset copy commands.

Production status:

```text
production-approved on 2026-07-15
```

The user confirmed that version `1.1.1` is installed and working as expected
on both GCR staging and GCR production.

## GCR 1.1.0 Promotion Packages

Staging-approved package:

```text
redmine_project_percent_done-1.1.0-staging-20260701.zip
```

Production package prepared on 2026-07-10:

```text
redmine_project_percent_done-1.1.0-production-20260710.zip
```

The Production package is a byte-for-byte copy of the approved Staging package.
Both packages have SHA-256:

```text
A68EE28370864D2A6AB598638BFE5E1A666DFB2605BCAB966F18738AA9571D4C
```

Staging acceptance is documented in `docs/STAGING_ACCEPTANCE_1.1.0.md`.
Production deployment instructions are documented in
`docs/PRODUCTION_RUNBOOK_1.1.0.md`.

Risk Monitor Pro 0.2.3 depends on Project Percent Done `>= 1.1.0` and Public
API V1. Promote and validate Project Percent Done 1.1.0 on Production before
deploying Risk Monitor Pro 0.2.3.

## Tag

```bash
git tag v1.1.0
git push origin v1.1.0
```
