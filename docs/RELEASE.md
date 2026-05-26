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

## Tag

```bash
git tag v1.0.0
git push origin v1.0.0
```
