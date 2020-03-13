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
              'run' => [%q{ruby -e 'puts "Hello"'}]
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
                  %q{ruby -e 'puts "Hello"'},
                  %q{ruby -e 'puts "Bye"'},
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
                  'commands' => %q{ruby -e 'puts "Hello"'},
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
                    'commands' => [%q{ruby -e 'puts "Hello"'}],
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
          expect(validation.errors.map(&:path)).to eq([[:docker, :build], [:docker, :run]])
        end
      end
    end
    
    context 'with a docker-compose task' do
      context 'with valid params' do
        let(:task) do
          {
            'docker-compose' => {
              'service' => 'app',
              'run' => [%q{ruby -e 'puts "Hello"'}]
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
                  %q{ruby -e 'puts "Hello"'},
                  %q{ruby -e 'puts "Bye"'},
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
                  'commands' => %q{ruby -e 'puts "Hello"'},
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
                    'commands' => [%q{ruby -e 'puts "Hello"'}],
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
          expect(validation.errors.map(&:path)).to eq([[:'docker-compose', :service], [:'docker-compose', :run]])
        end
      end
    end
  end
end

