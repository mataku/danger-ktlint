# danger-ktlint

Lint kotlin files using ktlint command lint interface.

## Installation

```ruby
$ gem install danger-ktlint
```

## Usage

You need to install `ktlint` command first, see: https://ktlint.github.io/#getting-started.

```ruby
# Dangerfile
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
