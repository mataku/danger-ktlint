# danger-ktlint

Lint kotlin files only changed files in a pull request using ktlint command lint interface.

## Installation

```ruby
gem install danger-ktlint
```

## Usage

You need to install `ktlint` command and set as executable first, see: https://ktlint.github.io/#getting-started.

```bash
# Example
curl --output /usr/local/bin/ktlint -sL https://github.com/pinterest/ktlint/releases/download/$KTLINT_VERSION/ktlint && chmod a+x /usr/local/bin/ktlint
```

Add this to Dangerfile.

```ruby
ktlint.lint

# If you want inline comments, specify `ktlint.lint` with `inline_mode: true`
# ktlint.lint(inline_mode: true)
```

### Options
#### Set maximum number of comments of ktlint results

Default is `nil`, all comments are sent.

```shell
ktlint.limit = 3
ktlint.lint
```

#### Skip ktlint task

Default is false.

```shell
ktlint.skip_lint = true
# If skip_lint is specified, report_file must also be specified.
ktlint.report_file = 'result.json'
ktlint.lint
```

## CHANGELOG

See [CHANGELOG.md](https://github.com/mataku/danger-ktlint/blob/master/CHANGELOG.md).

## TODO

- filtering: false (default: filtering: true behavior)
- Allow plain or html report_file (Currently only JSON is supported.)

## Development

1. Clone this repo
2. Run `bundle install` to setup dependencies.
3. Run `bundle exec rake spec` to run the tests.
4. Use `bundle exec guard` to automatically have tests run as you make changes.
5. Make your changes.
