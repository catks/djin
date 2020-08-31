# frozen_string_literal: true

RSpec.describe Djin::ConfigLoader do
  describe '.load!' do
    subject(:load!) { described_class.load!(config) }

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
