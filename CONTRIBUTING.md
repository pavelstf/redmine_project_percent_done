# Contributing

Thank you for considering a contribution to Redmine Project Percent Done.

## Development Principles

- Keep Redmine core patches to a minimum.
- Prefer Redmine hooks and service objects over monkey patches.
- Keep compatibility with Redmine 5.x and 6.x where practical.
- Avoid database migrations unless the feature clearly requires persistence.
- Treat permission behavior as a security-sensitive area.
- Keep calculation behavior explicit and documented.

## Local Development

Place the plugin in a Redmine checkout:

```text
REDMINE_ROOT/plugins/redmine_project_percent_done
```

Run plugin tests from the Redmine root:

```bash
RAILS_ENV=test bundle exec rake redmine:plugins:test NAME=redmine_project_percent_done
```

## Pull Request Checklist

- Explain the user-visible behavior change.
- Add or update tests for calculation changes.
- Update `README.md` or files in `docs/` when behavior changes.
- Update `CHANGELOG.md`.
- Run Ruby syntax and YAML checks.
- Verify that no secrets, local archives, or staging files are committed.

## Code Style

- Follow the style of the surrounding Redmine plugin code.
- Use plain Ruby service objects for calculation logic.
- Avoid comments that restate obvious code.
- Keep user-facing strings in locale files.

## Reporting Bugs

Please include:

- Redmine version.
- Ruby version.
- Rails version.
- Database adapter and version.
- Plugin version.
- Relevant plugin settings.
- Steps to reproduce.
- Relevant Redmine log excerpt.
