# frozen_string_literal: true

RSpec.describe Djin::TaskContract do
  let(:instance) { described_class.new }

  describe 'Task Validation' do
    subject(:validation) { instance.call(task) }

    context 'with a docker task' do
      context 'with valid params' do
        let(:task) do
          {
            'docker' => {
              'image' => 'ruby:2.5',
              'run' => [%q(ruby -e 'puts "Hello"')]
            }
          }
        end

        it 'is expect to be valid' do
          is_expected.to be_success
        end

        context 'with multiple commands' do
          let(:task) do
            {
              'docker' => {
                'image' => 'ruby:2.5',
                'run' => [
                  %q(ruby -e 'puts "Hello"'),
                  %q(ruby -e 'puts "Bye"')
                ]
              }
            }
          end

          it 'is expect to be valid' do
            is_expected.to be_success
          end
        end

        context 'in expanded form' do
          let(:task) do
            {
              'docker' => {
                'image' => 'ruby:2.5',
                'run' => {
                  'commands' => %q(ruby -e 'puts "Hello"'),
                  'options' => '--rm'
                }
              }
            }
          end

          it 'is expect to be valid' do
            is_expected.to be_success
          end

          context 'with multiple commands' do
            let(:task) do
              {
                'docker' => {
                  'image' => 'ruby:2.5',
                  'run' => {
                    'commands' => [%q(ruby -e 'puts "Hello"')],
                    'options' => '--rm'
                  }
                }
              }
            end

            it 'is expect to be valid' do
              is_expected.to be_success
            end
          end
        end
      end

      context 'with invalid params' do
        let(:task) do
          {
            'docker' => {
              'build' => 10,
              'image' => 'ruby:2.5',
              'run' => 42
            }
          }
        end

        it 'is expected to be invalid' do
          is_expected.to be_a_failure
        end

        it 'returns the errors for the fields' do
          expect(validation.errors.map(&:path)).to eq([%i[docker build], %i[docker run]])
        end
      end
    end

    context 'with a docker-compose task' do
      context 'with valid params' do
        let(:task) do
          {
            'docker-compose' => {
              'service' => 'app',
              'run' => [%q(ruby -e 'puts "Hello"')]
            }
          }
        end

        it 'is expect to be valid' do
          is_expected.to be_success
        end

        context 'with multiple commands' do
          let(:task) do
            {
              'docker-compose' => {
                'service' => 'app',
                'run' => [
                  %q(ruby -e 'puts "Hello"'),
                  %q(ruby -e 'puts "Bye"')
                ]
              }
            }
          end

          it 'is expect to be valid' do
            is_expected.to be_success
          end
        end

        context 'in expanded form' do
          let(:task) do
            {
              'docker-compose' => {
                'service' => 'app',
                'run' => {
                  'commands' => %q(ruby -e 'puts "Hello"'),
                  'options' => '--rm'
                }
              }
            }
          end

          it 'is expect to be valid' do
            is_expected.to be_success
          end

          context 'with multiple commands' do
            let(:task) do
              {
                'docker-compose' => {
                  'service' => 'app',
                  'run' => {
                    'commands' => [%q(ruby -e 'puts "Hello"'), %q(ruby -e 'puts "Hello"')],
                    'options' => '--rm'
                  }
                }
              }
            end

            it 'is expect to be valid' do
              is_expected.to be_success
            end
          end
        end
      end

      context 'with invalid params' do
        let(:task) do
          {
            'docker-compose' => {
              'service' => 10,
              'run' => 42
            }
          }
        end

        it 'is expected to be invalid' do
          is_expected.to be_a_failure
        end

        it 'returns the errors for the fields' do
          expect(validation.errors.map(&:path)).to eq([%i[docker-compose service], %i[docker-compose run]])
        end
      end
    end

    context 'with a local task' do
      context 'with valid params' do
        let(:task) do
          {
            'local' => {
              'run' => [%q(ruby -e 'puts "Hello"')]
            }
          }
        end

        it 'is expect to be valid' do
          is_expected.to be_success
        end

        context 'with multiple commands' do
          let(:task) do
            {
              'local' => {
                'run' => [%q(ruby -e 'puts "Hello"'), 'pwd']
              }
            }
          end

          it 'is expect to be valid' do
            is_expected.to be_success
          end
        end

        context 'in expanded form' do
          let(:task) do
            {
              'local' => {
                'run' => {
                  'commands' => %q(ruby -e 'puts "Hello"')
                }
              }
            }
          end

          it 'is expect to be valid' do
            is_expected.to be_success
          end

          context 'with multiple commands' do
            let(:task) do
              {
                'local' => {
                  'run' => {
                    'commands' => [%q(ruby -e 'puts "Hello"'), %q(ruby -e 'puts "Hello"')]
                  }
                }
              }
            end

            it 'is expect to be valid' do
              is_expected.to be_success
            end
          end
        end
      end

      context 'with invalid params' do
        let(:task) do
          {
            'local' => {
              'run' => 42
            }
          }
        end

        it 'is expected to be invalid' do
          is_expected.to be_a_failure
        end

        it 'returns the errors for the fields' do
          expect(validation.errors.map(&:path)).to eq([%i[local run]])
        end
      end
    end

    context 'with a depends_on option' do
      context 'with docker-compose' do
        let(:task) do
          {
            'docker-compose' => {
              'service' => 'app',
              'run' => {
                'commands' => %q(ruby -e 'puts "Hello"'),
                'options' => '--rm'
              }
            },
            'depends_on' => ['another']
          }
        end

        it 'is expect to be valid' do
          is_expected.to be_success
        end
      end

      context 'with docker' do
        let(:task) do
          {
            'docker' => {
              'image' => 'ruby:2.5',
              'run' => [%q(ruby -e 'puts "Hello"')]
            },
            'depends_on' => ['another']
          }
        end

        it 'is expect to be valid' do
          is_expected.to be_success
        end
      end

      context 'without docker and docker-compose' do
        let(:task) do
          {
            'depends_on' => %w[another one bits]
          }
        end

        it 'is expect to be valid' do
          is_expected.to be_success
        end
      end
    end
  end
end
