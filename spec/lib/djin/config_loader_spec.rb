# frozen_string_literal: true

RSpec.describe Djin::ConfigLoader do
  describe '.load!' do
    subject(:load!) { described_class.load!(config_file.to_pathname) }

    let(:config_file) { TestFile.new(config) }

    let(:djin_version) { Djin::VERSION }
    let(:expected_raw_tasks) { expected_tasks }
    let(:expected_variables) { {} }

    let(:expected_file_config) do
      Djin::FileConfig.new(
        djin_version: djin_version,
        tasks: expected_tasks,
        raw_tasks: expected_raw_tasks,
        variables: expected_variables
      )
    end

    after do
      Djin.cache.clear
      config_file.close
    end

    # TODO: Remove in 1.0.0 Release
    context 'with legacy tasks' do
      let(:config) do
        {
          'djin_version' => djin_version,
          'default' => {
            'docker' => {
              'image' => 'ruby:2.5',
              'run' => [%q(ruby -e 'puts "Hello"')]
            }
          }
        }.to_yaml
      end

      let(:expected_tasks) do
        {
          'default' => {
            'docker' => {
              'image' => 'ruby:2.5',
              'run' => [%q(ruby -e 'puts "Hello"')]
            }
          }
        }
      end

      it 'returns the expected file config' do
        is_expected.to eq(expected_file_config)
      end

      context 'with a config with keys starting with underscore' do
        let(:config) do
          {
            'djin_version' => djin_version,
            '_hide' => 'this',
            'default' => {
              'docker' => {
                'image' => 'ruby:2.5',
                'run' => [%q(ruby -e 'puts "Hello"')]
              }
            }
          }.to_yaml
        end

        let(:expected_tasks) do
          {
            'default' => {
              'docker' => {
                'image' => 'ruby:2.5',
                'run' => [%q(ruby -e 'puts "Hello"')]
              }
            }
          }
        end

        it 'returns the config as a hash' do
          is_expected.to eq(expected_file_config)
        end
      end

      context 'with custom values for args' do
        let(:config) do
          {
            'djin_version' => djin_version,
            'default' => {
              'docker' => {
                'image' => 'ruby:2.5',
                'run' => ['rubocop {{args}}']
              }
            }
          }.to_yaml
        end

        let(:expected_tasks) do
          {
            'default' => {
              'docker' => {
                'image' => 'ruby:2.5',
                'run' => ['rubocop -a']
              }
            }
          }
        end

        let(:expected_raw_tasks) do
          {
            'default' => {
              'docker' => {
                'image' => 'ruby:2.5',
                'run' => ['rubocop {{args}}']
              }
            }
          }
        end

        let(:command_args) { ['some:task', '--', '-a'] }

        it 'returns a string with rendered args' do
          stub_const('ARGV', command_args)

          is_expected.to eq(expected_file_config)
        end
      end

      context 'when using args and args?' do
        let(:config) do
          {
            'djin_version' => djin_version,
            'default' => {
              'docker' => {
                'image' => 'some_image',
                'run' => ['echo "Hi{{#args?}}, I Have args{{/args?}}"']
              }
            }
          }.to_yaml
        end

        let(:expected_tasks) do
          {
            'default' => {
              'docker' => {
                'image' => 'some_image',
                'run' => ['echo "Hi, I Have args"']
              }
            }
          }
        end

        let(:expected_raw_tasks) do
          {
            'default' => {
              'docker' => {
                'image' => 'some_image',
                'run' => ['echo "Hi{{#args?}}, I Have args{{/args?}}"']
              }
            }
          }
        end

        context 'with args' do
          let(:command_args) { ['some:task', '--', '-a'] }

          it 'returns a string folowwinf the consitional' do
            stub_const('ARGV', command_args)

            is_expected.to eq(expected_file_config)
          end
        end

        context 'without args' do
          let(:command_args) { [] }

          let(:expected_tasks) do
            {
              'default' => {
                'docker' => {
                  'image' => 'some_image',
                  'run' => ['echo "Hi"']
                }
              }
            }
          end

          it 'returns a string folowwinf the consitional' do
            stub_const('ARGV', command_args)

            is_expected.to eq(expected_file_config)
          end
        end
      end

      context 'with environment variables' do
        let(:config) do
          {
            'djin_version' => djin_version,
            'default' => {
              'docker' => {
                'image' => 'some_image',
                'run' => ['ls {{#MULTIPLE_FILES}}{{FILES}}{{/MULTIPLE_FILES}}']
              }
            }
          }.to_yaml
        end

        let(:expected_tasks) do
          {
            'default' => {
              'docker' => {
                'image' => 'some_image',
                'run' => ['ls test test2']
              }
            }
          }
        end

        let(:expected_raw_tasks) do
          {
            'default' => {
              'docker' => {
                'image' => 'some_image',
                'run' => ['ls {{#MULTIPLE_FILES}}{{FILES}}{{/MULTIPLE_FILES}}']
              }
            }
          }
        end

        let(:command_args) { ['some:task', '--', '-a'] }
        let(:files) { 'test test2' }

        before do
          ENV['FILES'] = files
          ENV['MULTIPLE_FILES'] = 'true'
        end

        it 'returns a string with rendered args' do
          stub_const('ARGV', command_args)

          is_expected.to eq(expected_file_config)
        end
      end

      context 'with djin variables' do
        let(:config) do
          {
            'djin_version' => djin_version,
            'variables' => {
              'test_variable' => 'HelloTest'
            },
            'default' => {
              'docker' => {
                'image' => 'ruby:2.5',
                'run' => [%q(ruby -e 'puts "{{test_variable}}"')]
              }
            }
          }.to_yaml
        end

        let(:expected_variables) do
          { test_variable: 'HelloTest' }
        end

        let(:expected_tasks) do
          {
            'default' => {
              'docker' => {
                'image' => 'ruby:2.5',
                'run' => [%q(ruby -e 'puts "HelloTest"')]
              }
            }
          }
        end

        let(:expected_raw_tasks) do
          {
            'default' => {
              'docker' => {
                'image' => 'ruby:2.5',
                'run' => [%q(ruby -e 'puts "{{test_variable}}"')]
              }
            }
          }
        end

        it 'returns config tasks' do
          is_expected.to eq(expected_file_config)
        end

        context 'with a invalid configuration' do
          xit 'exits in error with the invalid configuration message'
        end
      end

      context 'without djin_version' do
        let(:config) do
          {
            'default' => {
              'docker' => {
                'image' => 'ruby:2.5',
                'run' => [%q(ruby -e 'puts "Hello"')]
              }
            }
          }.to_yaml
        end

        it 'exits in error' do
          expect { load! }.to raise_error(Djin::Interpreter::MissingVersionError)
        end
      end

      context 'with a bigger djin_version than the actual' do
        let(:version) { Vseries::SemanticVersion.new(djin_version).up(:patch).to_s }
        let(:config) do
          {
            'djin_version' => version,
            'default' => {
              'docker' => {
                'image' => 'ruby:2.5',
                'run' => [%q(ruby -e 'puts "Hello"')]
              }
            }
          }.to_yaml
        end

        it 'exits in error' do
          expect { load! }.to raise_error(Djin::Interpreter::VersionNotSupportedError)
        end
      end
    end

    context 'with a config without custom values' do
      let(:config) do
        {
          'djin_version' => djin_version,
          'tasks' => {
            'default' => {
              'docker' => {
                'image' => 'ruby:2.5',
                'run' => [%q(ruby -e 'puts "Hello"')]
              }
            }
          }
        }.to_yaml
      end

      let(:expected_tasks) do
        {
          'default' => {
            'docker' => {
              'image' => 'ruby:2.5',
              'run' => [%q(ruby -e 'puts "Hello"')]
            }
          }
        }
      end

      it 'returns the config as a hash' do
        is_expected.to eq(expected_file_config)
      end
    end

    context 'with a config with keys starting with underscore' do
      let(:config) do
        {
          'djin_version' => djin_version,
          '_hide' => 'this',
          'tasks' => {
            'default' => {
              'docker' => {
                'image' => 'ruby:2.5',
                'run' => [%q(ruby -e 'puts "Hello"')]
              }
            }
          }
        }.to_yaml
      end

      let(:expected_tasks) do
        {
          'default' => {
            'docker' => {
              'image' => 'ruby:2.5',
              'run' => [%q(ruby -e 'puts "Hello"')]
            }
          }
        }
      end

      it 'returns the config as a hash' do
        is_expected.to eq(expected_file_config)
      end
    end

    context 'with custom values for args' do
      let(:config) do
        {
          'djin_version' => djin_version,
          'tasks' => {
            'default' => {
              'docker' => {
                'image' => 'ruby:2.5',
                'run' => ['rubocop {{args}}']
              }
            }
          }
        }.to_yaml
      end

      let(:expected_tasks) do
        {
          'default' => {
            'docker' => {
              'image' => 'ruby:2.5',
              'run' => ['rubocop -a']
            }
          }
        }
      end

      let(:expected_raw_tasks) do
        {
          'default' => {
            'docker' => {
              'image' => 'ruby:2.5',
              'run' => ['rubocop {{args}}']
            }
          }
        }
      end

      let(:command_args) { ['some:task', '--', '-a'] }

      it 'returns a string with rendered args' do
        stub_const('ARGV', command_args)

        is_expected.to eq(expected_file_config)
      end
    end

    context 'when using args and args?' do
      let(:config) do
        {
          'djin_version' => djin_version,
          'tasks' => {
            'default' => {
              'docker' => {
                'image' => 'some_image',
                'run' => ['echo "Hi{{#args?}}, I Have args{{/args?}}"']
              }
            }
          }
        }.to_yaml
      end

      let(:expected_raw_tasks) do
        {
          'default' => {
            'docker' => {
              'image' => 'some_image',
              'run' => ['echo "Hi{{#args?}}, I Have args{{/args?}}"']
            }
          }
        }
      end

      context 'with args' do
        let(:command_args) { ['some:task', '--', '-a'] }

        let(:expected_tasks) do
          {
            'default' => {
              'docker' => {
                'image' => 'some_image',
                'run' => ['echo "Hi, I Have args"']
              }
            }
          }
        end

        it 'returns a string folowwinf the consitional' do
          stub_const('ARGV', command_args)

          is_expected.to eq(expected_file_config)
        end
      end

      context 'without args' do
        let(:command_args) { [] }

        let(:expected_tasks) do
          {
            'default' => {
              'docker' => {
                'image' => 'some_image',
                'run' => ['echo "Hi"']
              }
            }
          }
        end

        it 'returns a string folowwinf the consitional' do
          stub_const('ARGV', command_args)

          is_expected.to eq(expected_file_config)
        end
      end
    end

    context 'with environment variables' do
      let(:config) do
        {
          'djin_version' => djin_version,
          'tasks' => {
            'default' => {
              'docker' => {
                'image' => 'some_image',
                'run' => ['ls {{#MULTIPLE_FILES}}{{FILES}}{{/MULTIPLE_FILES}}']
              }
            }
          }
        }.to_yaml
      end

      let(:command_args) { ['some:task', '--', '-a'] }
      let(:files) { 'test test2' }

      before do
        ENV['FILES'] = files
        ENV['MULTIPLE_FILES'] = 'true'
      end

      let(:expected_tasks) do
        {
          'default' => {
            'docker' => {
              'image' => 'some_image',
              'run' => ['ls test test2']
            }
          }
        }
      end

      let(:expected_raw_tasks) do
        {
          'default' => {
            'docker' => {
              'image' => 'some_image',
              'run' => ['ls {{#MULTIPLE_FILES}}{{FILES}}{{/MULTIPLE_FILES}}']
            }
          }
        }
      end

      it 'returns a string with rendered args' do
        stub_const('ARGV', command_args)

        is_expected.to eq(expected_file_config)
      end
    end

    context 'with djin variables' do
      let(:config) do
        {
          'djin_version' => djin_version,
          'variables' => {
            'test_variable' => 'HelloTest'
          },
          'tasks' => {
            'default' => {
              'docker' => {
                'image' => 'ruby:2.5',
                'run' => [%q(ruby -e 'puts "{{test_variable}}"')]
              }
            }
          }
        }.to_yaml
      end

      let(:expected_variables) { { test_variable: 'HelloTest' } }

      let(:expected_tasks) do
        {
          'default' => {
            'docker' => {
              'image' => 'ruby:2.5',
              'run' => [%q(ruby -e 'puts "HelloTest"')]
            }
          }
        }
      end

      let(:expected_raw_tasks) do
        {
          'default' => {
            'docker' => {
              'image' => 'ruby:2.5',
              'run' => [%q(ruby -e 'puts "{{test_variable}}"')]
            }
          }
        }
      end

      it 'returns config tasks' do
        is_expected.to eq(expected_file_config)
      end
    end

    context 'with a description' do
      let(:config) do
        {
          'djin_version' => djin_version,
          'tasks' => {
            'default' => {
              'description' => 'Some description',
              'docker' => {
                'image' => 'ruby:2.5',
                'run' => [%q(ruby -e 'puts "Test"')]
              }
            }
          }
        }.to_yaml
      end

      let(:expected_tasks) do
        {
          'default' => {
            'description' => 'Some description',
            'docker' => {
              'image' => 'ruby:2.5',
              'run' => [%q(ruby -e 'puts "Test"')]
            }
          }
        }
      end

      it 'returns config tasks' do
        is_expected.to eq(expected_file_config)
      end
    end

    context 'with aliases' do
      let(:config) do
        {
          'djin_version' => djin_version,
          'tasks' => {
            'default' => {
              'docker' => {
                'image' => 'ruby:2.5',
                'run' => [%q(ruby -e 'puts "Test"')]
              },
              'aliases' => ['theone']
            }
          }
        }.to_yaml
      end

      let(:expected_tasks) do
        {
          'default' => {
            'docker' => {
              'image' => 'ruby:2.5',
              'run' => [%q(ruby -e 'puts "Test"')]
            },
            'aliases' => ['theone']
          }
        }
      end

      it 'returns config tasks' do
        is_expected.to eq(expected_file_config)
      end
    end

    context 'with include option' do
      let(:config) do
        {
          'djin_version' => djin_version,
          'include' => [
            {
              'file' => file_to_include_path,
              'context' => {
                'variables' => {
                  'namespace' => 'some_namespace:'
                }
              }
            },
            {
              'file' => file_to_include_path,
              'context' => {
                'variables' => {
                  'namespace' => 'some_namespace2:'
                }
              }
            }
          ],
          'tasks' => {
            'default' => {
              'docker' => {
                'image' => 'ruby:2.5',
                'run' => [%q(ruby -e 'puts "Test"')]
              }
            }
          }
        }.to_yaml
      end

      let(:config_to_include) do
        {
          'djin_version' => djin_version,
          'variables' => {
            'ruby_version' => '2.6'
          },
          'tasks' => {
            '"{{namespace}}default"' => {
              'docker' => {
                'image' => '"ruby:{{ruby_version}}"',
                'run' => [%q(ruby -e 'puts "Test"')]
              }
            }
          }
        }.to_yaml
      end

      context 'when the file exists' do
        let(:file_to_include_path) { TestFile.new(config_to_include).path }
        # TODO: Improve runtime config variables behaviour, in the current implementation
        #       if multiple files are included with variables with the same name, only the
        #       last variable is persisted in the FileConfig#variables, maybe create another
        #       field to persist (eg: runtime_variables) all the variables in the include -> context?
        let(:expected_variables) { { ruby_version: '2.6', namespace: 'some_namespace2:' } }

        let(:expected_tasks) do
          {
            '"some_namespace:default"' => {
              'docker' => {
                'image' => '"ruby:2.6"',
                'run' => [%q(ruby -e 'puts "Test"')]
              }
            },
            '"some_namespace2:default"' => {
              'docker' => {
                'image' => '"ruby:2.6"',
                'run' => [%q(ruby -e 'puts "Test"')]
              }
            },
            'default' => {
              'docker' => {
                'image' => 'ruby:2.5',
                'run' => [%q(ruby -e 'puts "Test"')]
              }
            }
          }
        end

        let(:expected_raw_tasks) do
          {
            '"{{namespace}}default"' => {
              'docker' => {
                'image' => '"ruby:{{ruby_version}}"',
                'run' => [%q(ruby -e 'puts "Test"')]
              }
            },
            'default' => {
              'docker' => {
                'image' => 'ruby:2.5',
                'run' => [%q(ruby -e 'puts "Test"')]
              }
            }
          }
        end

        it 'returns the config file' do
          is_expected.to eq(expected_file_config)
        end

        context 'when reading a file more that one time' do
          it 'load the file and cache for the second read' do
            file_to_include = Pathname.new(file_to_include_path)

            allow(Pathname).to receive(:new).and_return(file_to_include)

            allow(file_to_include).to receive(:read).and_return(config_to_include)

            described_class.load!(config_file.to_pathname)
            described_class.load!(config_file.to_pathname)

            expect(file_to_include).to have_received(:read).once
          end
        end

        context 'with a recursive include' do
          xit 'raise error of recursive reference'
        end

        context 'and no tasks are defined in main djin.yml' do
          xit 'loads the tasks'
        end
      end

      context 'when the file doesnt exists' do
        let(:file_to_include_path) { 'no_ecziste' }
        it 'exits in error' do
          expect { load! }.to raise_error(Djin::Interpreter::InvalidConfigFileError)
        end
      end

      context 'with a invalid configuration' do
        xit 'exits in error with the invalid configuration message'
      end
    end

    context 'without djin_version' do
      let(:config) do
        {
          'tasks' => {
            'default' => {
              'docker' => {
                'image' => 'ruby:2.5',
                'run' => [%q(ruby -e 'puts "Hello"')]
              }
            }
          }
        }.to_yaml
      end

      it 'exits in error' do
        expect { load! }.to raise_error(Djin::Interpreter::MissingVersionError)
      end
    end

    context 'with a bigger djin_version than the actual' do
      let(:version) { Vseries::SemanticVersion.new(djin_version).up(:patch).to_s }
      let(:config) do
        {
          'djin_version' => version,
          'tasks' => {
            'default' => {
              'docker' => {
                'image' => 'ruby:2.5',
                'run' => [%q(ruby -e 'puts "Hello"')]
              }
            }
          }
        }.to_yaml
      end

      it 'exits in error' do
        expect { load! }.to raise_error(Djin::Interpreter::VersionNotSupportedError)
      end
    end

    context 'with a invalid yaml' do
      let(:config) do
        <<~CONFIG_YAML
          teste
          :test: 'test'
        CONFIG_YAML
      end

      it 'exits in error' do
        expect { load! }.to raise_error(Djin::Interpreter::InvalidConfigFileError)
      end
    end
  end
end
