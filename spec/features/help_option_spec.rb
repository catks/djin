# frozen_string_literal: true

RSpec.describe '--help option', type: :feature do
  it 'returns the help' do
    run_command('djin --help')

    expected = <<~DESC
      Commands:
        djin --version                                  # Prints Djin Version
        djin -f FILEPATH                                # Specify a djin file to load (default: djin.yml)
        djin lint                                       # Lint
        djin release                                    # Runs: verto tag up {{args}} && bundle exec rake release
        djin remote-config [SUBCOMMAND]
        djin run                                        # Runs: docker-compose run --rm --entrypoint='' app sh -c "sh -c '{{args}}'"
        djin sh                                         # Enter app service shell
        djin test                                       # Runs Specs
    DESC

    expect(command_stderr).to eq(expected)
  end

  context 'with a -f option' do
    it 'returns the help for the other file' do
      run_command('djin -f examples/djin.yml --help')

      expected = <<~DESC
        Commands:
          djin --version                                  # Prints Djin Version
          djin -f FILEPATH                                # Specify a djin file to load (default: djin.yml)
          djin default                                    # Runs: docker run ruby:2.5 sh -c "ruby -e 'puts \\" Hello\\"'"
          djin remote-config [SUBCOMMAND]
          djin script                                     # Runs: docker run --rm -v $(pwd)/my_ruby_script.rb:/scripts/my_ruby_script.rb ruby:2.6 sh -c "ruby /scripts/my_ruby_script.rb"
          djin test2:unit                                 # Runs: docker-compose run --rm --entrypoint='' app sh -c "cd /usr/src/djin && rspec "
          djin test:unit                                  # Runs: docker-compose run --rm --entrypoint='' app sh -c "cd /usr/src/djin && rspec "
          djin with_build                                 # Runs: docker run djin_djin_with_build sh -c "ruby -e 'puts " Hello"'"
      DESC

      expect(command_stderr).to eq(expected)
    end
  end
end
