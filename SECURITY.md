# Security Policy

## Supported Versions

| Version | Supported |
|---|---|
| 1.0.x | Yes |

## Reporting a Vulnerability

Please report suspected security issues privately to the project maintainers.

Do not publish details publicly until the issue has been reviewed and a fix or mitigation is available.

## Security Model

The plugin calculates the final project percentage from all issues in the project, regardless of the current user's issue visibility.

This is intentional because the value represents absolute project progress.

The detailed breakdown page renders concrete issue rows only for issues visible to the current user. If some issues are hidden, the page shows an explanatory warning.

## Areas Requiring Care

- Issue visibility and permission checks.
- REST API exposure.
- Future caching behavior.
- Any future SQL aggregation changes.
- Any future persistent storage or background recalculation.
