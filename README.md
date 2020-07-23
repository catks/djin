# Djin

![](https://github.com/catks/djin/workflows/Ruby/badge.svg?branch=master)
[![Maintainability](https://api.codeclimate.com/v1/badges/824a2e78399813543212/maintainability)](https://codeclimate.com/github/catks/djin/maintainability)

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
djin_version: '0.6.0'

tasks:
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
djin_version: '0.6.0'

_default_run_options: &default_run_options
  options: "--rm"

tasks: 
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

Or mix local commands and docker/docker-compose commands:

```yaml
djin_version: '0.6.0'

_default_run_options: &default_run_options
  options: "--rm"

tasks:
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

  "setup:copy_samples":
    local:
      run:
        - cp config/database.yml.sample config/database.yml

  "setup":
    depends_on:
      - "setup:copy_samples"
      - "db:create"
      - "db:migrate"
```

After that you can run `djin {{task_name}}`, like `djin script` or `djin test`

## Using Environment variables, custom variables and custom args in djin.yml tasks

You can also use environment variables using the '{{YOUR_ENV_HERE}}' syntax, like so:

```yaml
djin_version: '0.6.0'

_default_run_options: &default_run_options
  options: "--rm"

tasks:
  "db:migrate":
    docker-compose:
      service: app
      run:
        commands: ENV={{ENV}} rake db:migrate
        <<: *default_run_options

```

Or define some variables to use in multiple locations
```yaml
djin_version: '0.6.0'

_default_run_options: &default_run_options
  options: "--rm"

variables:
  my_ssh_user: user
  some_host: test.local

tasks:
  "some_host:ssh":
    local:
      run:
        - ssh {{my_ssh_user}}@{{some_host}}

  "some_host:logs":
    local:
      run:
        - ssh -t {{my_ssh_user}}@{{some_host}} 'tail -f /var/log/syslog'
```

It's also possible to pass custom arguments to the command, which means is possible to make a djin task act like the command itself:

```yaml
djin_version: '0.6.0'

_default_run_options: &default_run_options
  options: "--rm"

tasks:
  "rubocop":
    docker-compose:
      service: app
      run:
        commands: rubocop {{args}}
        <<: *default_run_options

```

With that you can pass custom args after `--`, eg: `djin rubocop -- --parallel`, which wil make djin runs `rubocop --parallel` inside the service `app`.

Under the hood djin uses [Mustache](https://mustache.github.io/), so you can use other features like conditionals: `{{#IS_ENABLE}} Enabled {{/IS_ENABLE}}` (for args use the `args?`, eg: `{{#args?} {{args}} --and-other-thing{{/args?}}`), to see more more options you can access this [Link](https://mustache.github.io/mustache.5.html)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, run `djin release -- {{increment_option}}` (where {{incremment_option}} can be `--patch`, `--minor` or `major`), which will change version, update the CHANGELOG.md, create a new commit, create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## TODO:

1. Adds a `-f` option to load custom djin files

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/catks/djin.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
