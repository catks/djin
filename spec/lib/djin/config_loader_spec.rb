# frozen_string_literal: true

RSpec.describe Djin::ConfigLoader do
  describe '.load!' do
    subject(:load!) { described_class.load!(template) }

    # TODO: Remove in 1.0.0 Release
    context 'with legacy tasks' do
      let(:template) do
        {
          'djin_version' => Djin::VERSION,
          'default' => {
            'docker' => {
              'image' => 'ruby:2.5',
              'run' => [%q(ruby -e 'puts "Hello"')]
            }
          }
        }.to_yaml
      end

      it 'returns the template as a hash' do
        expected_template = {
          'default' => {
            'docker' => {
              'image' => 'ruby:2.5',
              'run' => [%q(ruby -e 'puts "Hello"')]
            }
          }
        }
        is_expected.to eq(expected_template)
      end

      context 'with a template with keys starting with underscore' do
        let(:template) do
          {
            'djin_version' => Djin::VERSION,
            '_hide' => 'this',
            'default' => {
              'docker' => {
                'image' => 'ruby:2.5',
                'run' => [%q(ruby -e 'puts "Hello"')]
              }
            }
          }.to_yaml
        end

        it 'returns the template as a hash' do
          expected_template = {
            'default' => {
              'docker' => {
                'image' => 'ruby:2.5',
                'run' => [%q(ruby -e 'puts "Hello"')]
              }
            }
          }
          is_expected.to eq(expected_template)
        end
      end

      context 'with custom values for args' do
        let(:template) do
          {
            'djin_version' => Djin::VERSION,
            'default' => {
              'docker' => {
                'image' => 'ruby:2.5',
                'run' => ['rubocop {{args}}']
              }
            }
          }.to_yaml
        end

        let(:command_args) { ['some:task', '--', '-a'] }

        it 'returns a string with rendered args' do
          stub_const('ARGV', command_args)

          expected_rendered_template = {
            'default' => {
              'docker' => {
                'image' => 'ruby:2.5',
                'run' => ['rubocop -a']
              }
            }
          }
          is_expected.to eq(expected_rendered_template)
        end
      end

      context 'when using args and args?' do
        let(:template) do
          {
            'djin_version' => Djin::VERSION,
            'default' => {
              'docker' => {
                'image' => 'some_image',
                'run' => ['echo "Hi{{#args?}}, I Have args{{/args?}}"']
              }
            }
          }.to_yaml
        end

        context 'with args' do
          let(:command_args) { ['some:task', '--', '-a'] }

          it 'returns a string folowwinf the consitional' do
            stub_const('ARGV', command_args)

            expected_rendered_template = {
              'default' => {
                'docker' => {
                  'image' => 'some_image',
                  'run' => ['echo "Hi, I Have args"']
                }
              }
            }
            is_expected.to eq(expected_rendered_template)
          end
        end

        context 'without args' do
          let(:command_args) { [] }

          it 'returns a string folowwinf the consitional' do
            stub_const('ARGV', command_args)

            expected_rendered_template = {
              'default' => {
                'docker' => {
                  'image' => 'some_image',
                  'run' => ['echo "Hi"']
                }
              }
            }
            is_expected.to eq(expected_rendered_template)
          end
        end
      end

      context 'with environment variables' do
        let(:template) do
          {
            'djin_version' => Djin::VERSION,
            'default' => {
              'docker' => {
                'image' => 'some_image',
                'run' => ['ls {{#MULTIPLE_FILES}}{{FILES}}{{/MULTIPLE_FILES}}']
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

        it 'returns a string with rendered args' do
          stub_const('ARGV', command_args)

          expected_rendered_template = {
            'default' => {
              'docker' => {
                'image' => 'some_image',
                'run' => ['ls test test2']
              }
            }
          }
          is_expected.to eq(expected_rendered_template)
        end
      end

      context 'with djin variables' do
        let(:template) do
          {
            'djin_version' => Djin::VERSION,
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

        it 'returns template tasks' do
          expected_rendered_template = {
            'default' => {
              'docker' => {
                'image' => 'ruby:2.5',
                'run' => [%q(ruby -e 'puts "HelloTest"')]
              }
            }
          }
          is_expected.to eq(expected_rendered_template)
        end
      end

      context 'without djin_version' do
        let(:template) do
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
        let(:version) { Vseries::SemanticVersion.new(Djin::VERSION).up(:patch).to_s }
        let(:template) do
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

    context 'with a template without custom values' do
      let(:template) do
        {
          'djin_version' => Djin::VERSION,
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

      it 'returns the template as a hash' do
        expected_template = {
          'default' => {
            'docker' => {
              'image' => 'ruby:2.5',
              'run' => [%q(ruby -e 'puts "Hello"')]
            }
          }
        }
        is_expected.to eq(expected_template)
      end
    end

    context 'with a template with keys starting with underscore' do
      let(:template) do
        {
          'djin_version' => Djin::VERSION,
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

      it 'returns the template as a hash' do
        expected_template = {
          'default' => {
            'docker' => {
              'image' => 'ruby:2.5',
              'run' => [%q(ruby -e 'puts "Hello"')]
            }
          }
        }
        is_expected.to eq(expected_template)
      end
    end

    context 'with custom values for args' do
      let(:template) do
        {
          'djin_version' => Djin::VERSION,
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

      let(:command_args) { ['some:task', '--', '-a'] }

      it 'returns a string with rendered args' do
        stub_const('ARGV', command_args)

        expected_rendered_template = {
          'default' => {
            'docker' => {
              'image' => 'ruby:2.5',
              'run' => ['rubocop -a']
            }
          }
        }
        is_expected.to eq(expected_rendered_template)
      end
    end

    context 'when using args and args?' do
      let(:template) do
        {
          'djin_version' => Djin::VERSION,
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

      context 'with args' do
        let(:command_args) { ['some:task', '--', '-a'] }

        it 'returns a string folowwinf the consitional' do
          stub_const('ARGV', command_args)

          expected_rendered_template = {
            'default' => {
              'docker' => {
                'image' => 'some_image',
                'run' => ['echo "Hi, I Have args"']
              }
            }
          }
          is_expected.to eq(expected_rendered_template)
        end
      end

      context 'without args' do
        let(:command_args) { [] }

        it 'returns a string folowwinf the consitional' do
          stub_const('ARGV', command_args)

          expected_rendered_template = {
            'default' => {
              'docker' => {
                'image' => 'some_image',
                'run' => ['echo "Hi"']
              }
            }
          }
          is_expected.to eq(expected_rendered_template)
        end
      end
    end

    context 'with environment variables' do
      let(:template) do
        {
          'djin_version' => Djin::VERSION,
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

      it 'returns a string with rendered args' do
        stub_const('ARGV', command_args)

        expected_rendered_template = {
          'default' => {
            'docker' => {
              'image' => 'some_image',
              'run' => ['ls test test2']
            }
          }
        }
        is_expected.to eq(expected_rendered_template)
      end
    end

    context 'with djin variables' do
      let(:template) do
        {
          'djin_version' => Djin::VERSION,
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

      it 'returns template tasks' do
        expected_rendered_template = {
          'default' => {
            'docker' => {
              'image' => 'ruby:2.5',
              'run' => [%q(ruby -e 'puts "HelloTest"')]
            }
          }
        }
        is_expected.to eq(expected_rendered_template)
      end
    end

    context 'without djin_version' do
      let(:template) do
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
      let(:version) { Vseries::SemanticVersion.new(Djin::VERSION).up(:patch).to_s }
      let(:template) do
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
  end
end
