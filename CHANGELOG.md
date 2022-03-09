## Unreleased

## 0.0.7

- Support multiple ktlint result json by `ktlint.report_files_pattern = '...'`. e.g. `ktlint.report_files_pattern = '**/report.json'

## 0.0.6

- Support GitLab and BitBucket server even if `inline_mode: false` is specified.

## 0.0.5

### Fixed

- Fixed to not check ktlint binary even when skip_task is specified.

## 0.0.4

### Added
- ktlint task can be skipped by specifing `ktlint.skip_lint = true` and `ktlint.report_file = '...'`

## 0.0.3
### Added
- `limit` parameter to set the maximum number of comments of ktlint results.

## 0.0.2
### Added
- Inline comment feature (`inline_mode: true` with ktlint.lint)

## 0.0.1
### Added
- Run ktlint by ktlint.lint
