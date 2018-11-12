# danger-ktlint

Lint kotlin files using ktlint command lint interface.

## Installation

```ruby
$ gem install danger-ktlint
```

## Usage

You need to install `ktlint` command and set as executable first, see: https://ktlint.github.io/#getting-started.

```bash
# Example
$ curl --output /usr/local/bin/ktlint -sL https://github.com/shyiko/ktlint/releases/download/$KTLINT_VERSION/ktlint && chmod a+x /usr/loca/bin/ktlint
```

Add this to Dangerfile.

```ruby
ktlint.lint
```

## TODO

- filtering: false (default: filtering: true behavior)

## Development

1. Clone this repo
2. Run `bundle install` to setup dependencies.
3. Run `bundle exec rake spec` to run the tests.
4. Use `bundle exec guard` to automatically have tests run as you make changes.
5. Make your changes.
