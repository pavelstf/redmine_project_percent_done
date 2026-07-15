# Testing Log

## 2026-07-10 - 1.1.1 Administration Settings Help UI

Prepared Project Percent Done `1.1.1` as a UX consistency patch for the
Administration → Plugins → Project Percent Done settings page.

Scope:

- added help icons to every administrative setting;
- added concise English and Bulgarian help copy;
- followed the Budget Risk Monitor / Risk Monitor Pro help UX model:
  `button.icon-help`, custom `data-tooltip`, hover/focus/tap support, Escape to
  close, and no native `title` tooltip on help buttons;
- added minimal plugin stylesheet for compact help icons and tooltip styling;
- did not change calculation behavior, REST output, Public API V1, algorithm
  version, or Risk Monitor integration contract.

Validation notes:

- local static checks completed:
  - `ruby -c init.rb`
  - Ruby syntax check for `lib`, `app`, and `test`
  - YAML parsing for every locale file
  - ERB compile for every `.erb` view
  - `ruby -c app/views/project_percent_done/show.api.rsb`
  - EN/BG help locale parity check: 8 help keys
  - settings partial check confirmed help buttons use `data-tooltip` and no
    native `title=`
  - `git diff --check` reported no whitespace errors, only Windows LF/CRLF
    warnings
- staging package prepared:
  - `redmine_project_percent_done-1.1.1-staging-20260710.zip`
  - SHA-256:
    `A5DEFBC04FE6C5FBABB42661B80D21B33702147100EFB9C9C97E3E5315466388`
- staging was confirmed OK by the user on 2026-07-10;
- production package prepared as a byte-for-byte copy of the accepted staging
  package:
  - `redmine_project_percent_done-1.1.1-production-20260710.zip`
  - SHA-256:
    `A5DEFBC04FE6C5FBABB42661B80D21B33702147100EFB9C9C97E3E5315466388`
- production was confirmed OK by the user on 2026-07-15; version `1.1.1`
  is installed and working as expected on both GCR staging and GCR production;
- full Redmine plugin tests still require a Redmine checkout and test
  environment; this plugin-only Windows workspace does not contain Redmine's
  root `test/test_helper`.
