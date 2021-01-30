# Djin

![](https://github.com/catks/djin/workflows/Ruby/badge.svg?branch=master)
[![Maintainability](https://api.codeclimate.com/v1/badges/824a2e78399813543212/maintainability)](https://codeclimate.com/github/catks/djin/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/824a2e78399813543212/test_coverage)](https://codeclimate.com/github/catks/djin/test_coverage)

Djin is a make-like utility for docker containers

## Installation

Djin is distributed as a Ruby Gem, to install simple run:

    $ gem install djin

### With Rbenv

If you use Rbenv you can install djin only once and create an alias in your .basrc, .zshrc, etc:

#### ZSH
    $ RBENV_VERSION=$(rbenv global) gem install djin && echo "alias djin='RBENV_VERSION=$(rbenv global) djin'" >> ~/.zshrc

### Bash
    $ RBENV_VERSION=$(rbenv global) gem install djin && echo "alias djin='RBENV_VERSION=$(rbenv global) djin'" >> ~/.bashrc

## Usage

To use djin first you need to create a djin.yml file:

```yaml
djin_version: '0.11.3'

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
    aliases: # Optional Array of strings
      - rspec
```

You can also set task dependencies with depends_on option:


```yaml
djin_version: '0.11.3'

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
djin_version: '0.11.3'

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
djin_version: '0.11.3'

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
djin_version: '0.11.3'

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
djin_version: '0.11.3'

_default_run_options: &default_run_options
  options: "--rm"

tasks:
  "rubocop":
    docker-compose:
      service: app
      run:
        commands: rubocop {{args}}
        <<: *default_run_options
    aliases:
      - lint

```

With that, you can pass custom args after `--`, eg: `djin rubocop -- --parallel`, which will make djin runs `rubocop --parallel` inside the service `app`.

Under the hood djin uses [Mustache](https://mustache.github.io/), so you can use other features like conditionals: `{{#IS_ENABLE}} Enabled {{/IS_ENABLE}}` (for args use the `args?`, eg: `{{#args?}} {{args}} --and-other-thing{{/args?}}`), to see more more options you can access this [Link](https://mustache.github.io/mustache.5.html)

### Reusing tasks

If you have multiple tasks with similar behavior and with small differences you can use the `include` keyword, so this:

```yaml
djin_version: '0.11.3'

tasks:
  "host1:ssh":
    local:
      run:
        - ssh my_user@host1.com.br

  "host1:restart":
    local:
      run:
        - ssh -t my_user@host1.com.br restart

  "host1:logs":
    local:
      run:
        - ssh -t my_user@host1.com.br tail -f /var/log/my_log

  "host2:ssh":
    local:
      run:
        - ssh my_user@host2.com.br

  "host2:restart":
    local:
      run:
        - ssh -t my_user@host2.com.br restart

  "host2:logs":
    local:
      run:
        - ssh -t my_user@host2.com.br tail -f /var/log/my_file

```

can become this:

```yaml
# djin.yml
djin_version: '0.11.3'

include:
  - file: '.djin/server_tasks.yml'
    context:
      variables:
        namespace: host1
        host: host1.com
        ssh_user: my_user

  - file: '.djin/server_tasks.yml'
    context:
      variables:
        namespace: host2
        host: host2.com
        ssh_user: my_user

```


```yaml
# .djin/server_tasks.yml
djin_version: '0.11.3'

tasks:
  "{{namespace}}:ssh":
    local:
      run:
        - ssh {{ssh_user}}@{{host}}

  "{{namespace}}:restart":
    local:
      run:
        - ssh -t {{ssh_user}}@{{host}} restart

  "{{namespace}}:logs":
    local:
      run:
        - ssh -t {{ssh_user}}@{{host}} tail -f /var/log/my_log
```

You can also reuse tasks in some git repository, to do that you need to declare a git source and optionally a version:

```yaml
djin_version: '0.11.3'

include:
  - git: 'https://github.com/catks/djin.git'
    version: 'master'
    file: 'examples/djin_lib/test.yml'
    context:
      variables:
        namespace: 'remote:'

```

After that run `djin remote-config fetch` to fetch the repo and you can start using the tasks (All remote repos are cloned in `~/.djin/remote`)

See `djin remote-config` to learn more.

### Loading custom files

You can also specify a file to be read by djin with `-f`, eg:

```bash
djin -f my_file.yml # Returns the help for all tasks in my_file
djin -f my_file.yml build # Execute the build task defined in my_file.yml
```

You can also specify multiple files to join tasks between files:

```bash
# Mix the tasks
djin -f my_file.yml -f my_file2.yml # Returns the help for all tasks in my_file
djin -f my_file.yml -f my_file2.yml build # Execute the build task defined in my_file.yml or my_file2.yml
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, run `djin release -- {{increment_option}}` (where {{incremment_option}} can be `--patch`, `--minor` or `major`), which will change version, update the CHANGELOG.md, create a new commit, create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).


## TODO

1. Enable multiple -f options to merge configuration between files
2. Option to export tasks to Makefile
3. djin-export docker image to create and sync makefiles
4. include a key option to add tasks in git repositories files (maybe with a local cache)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/catks/djin.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
