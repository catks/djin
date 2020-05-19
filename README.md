# Djin

![](https://github.com/catks/djin/workflows/Ruby/badge.svg?branch=master)

Djin is a make-like utility for docker containers

## Installation

Djin is distributed as a Ruby Gem, to install simple run:

    $ gem install djin

### With Rbenv

If you use Rbenv you can install djin only once and create a alias in your .basrc, .zshrc, etc:

#### ZSH
    $ RBENV_VERSION=$(rbenv global) gem install djin && echo "alias djin='RBENV_VERSION=$(rbenv global) djin'" >> ~/.zshrc

### Bash
    $ RBENV_VERSION=$(rbenv global) gem install djin && echo "alias djin='RBENV_VERSION=$(rbenv global) djin'" >> ~/.bashrc

## Usage

To use djin first you need to create a djin.yml file:

```yaml
djin_version: '0.3.0'

# With a docker image
script:
  docker:
    image: "ruby:2.6"
    run:
      commands:
        - "ruby /scripts/my_ruby_script.rb"
      options: "--rm -v $(pwd)/my_ruby_script.rb:/scripts/my_ruby_script.rb"

# Using a docker-compose service
test:
  docker-compose:
    service: app
    run:
      commands: rspec
      options: "--rm"

```

You can also set task dependencies with depends_on option:


```yaml
djin_version: '0.3.0'

_default_run_options: &default_run_options
  options: "--rm"

"db:create":
  docker-compose:
    service: app
    run:
      commands: rake db:create
      <<: *default_run_options

"db:migrate":
  docker-compose:
    service: app
    run:
      commands: rake db:migrate
      <<: *default_run_options

"db:setup":
  depends_on:
    - "db:create"
    - "db:migrate"

```

After that you can run `djin {{task_name}}`, like `djin script` or `djin test`

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## TODO:

1. Adds a `-f` option to load custom djin files

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/catks/djin.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
