RSpec.describe Djin::Interpreter do
  describe '.load!' do
    subject(:load!) { described_class.load!(params) }

    context 'with a docker command' do
      let(:params) do
        {
          'djin_version' => Djin::VERSION,
          'default' => {
            'docker' => {
              'image' => 'ruby:2.5',
              'run' => [%q{ruby -e 'puts "Hello"'}]
            }
          }
        }
      end

      it 'load a task with the docker command' do
        is_expected.to eq([
          Djin::Task.new(name: 'default', command: %Q{docker run ruby:2.5 sh -c "ruby -e 'puts \"Hello\"'"})
        ])
      end

      context 'with multiples commands' do
        let(:params) do
          {
            'djin_version' => Djin::VERSION,
            'default' => {
              'docker' => {
                'image' => 'ruby:2.5',
                'run' => [
                  %q{ruby -e 'puts "Hello"'},
                  %q{ruby -e 'puts "Bye"'},
                ]
              }
            }
          }
        end

        it 'load a task with the docker command' do
          is_expected.to eq([
            Djin::Task.new(name: 'default',
                           command: %Q{docker run ruby:2.5 sh -c "ruby -e 'puts \"Hello\"' && ruby -e 'puts \"Bye\"'"})
          ])
        end
      end

      context 'with expanded run form' do
        let(:params) do
          {
            'djin_version' => Djin::VERSION,
            'default' => {
              'docker' => {
                'image' => 'ruby:2.5',
                'run' => {
                  'commands' => %q{ruby -e 'puts "Hello"'},
                  'options' => '--rm'
                }
              }
            }
          }
        end

        it 'load a task with the docker command' do
          is_expected.to eq([
            Djin::Task.new(name: 'default', command: %Q{docker run --rm ruby:2.5 sh -c "ruby -e 'puts \"Hello\"'"})
          ])
        end

        context 'with build option' do
          before do
            allow(Pathname).to receive(:getwd).and_return(Pathname.new('current_folder'))
          end

          let(:params) do
            {
              'djin_version' => Djin::VERSION,
              'default' => {
                'docker' => {
                  'build' => '.',
                  'run' => {
                    'commands' => %q{ruby -e 'puts "Hello"'},
                    'options' => '--rm'
                  }
                }
              }
            }
          end

          it 'load a task with the docker command' do
            is_expected.to eq([
              Djin::Task.new(name: 'default',
                             build_command: 'docker build . -t djin_current_folder_default',
                             command: %Q{docker run --rm djin_current_folder_default sh -c "ruby -e 'puts \"Hello\"'"})
            ])
          end
        end

        context 'with build option in expanded form' do
          before do
            allow(Pathname).to receive(:getwd).and_return(Pathname.new('current_folder'))
          end

          let(:params) do
            {
              'djin_version' => Djin::VERSION,
              'default' => {
                'docker' => {
                  'build' => {
                    'context' => 'another/path',
                    'options' => '-f Dockerfile.other'
                  },
                  'run' => {
                    'commands' => %q{ruby -e 'puts "Hello"'},
                    'options' => '--rm'
                  }
                }
              }
            }
          end

          it 'load a task with the docker command' do
            is_expected.to eq([
              Djin::Task.new(name: 'default',
                             build_command: 'docker build another/path -f Dockerfile.other -t djin_current_folder_default',
                             command: %Q{docker run --rm djin_current_folder_default sh -c "ruby -e 'puts \"Hello\"'"})
            ])
          end
        end
      end
    end
    context 'with a docker-compose command' do
      let(:params) do
        {
          'djin_version' => Djin::VERSION,
          'default' => {
            'docker-compose' => {
              'service' => 'app',
              'run' => [%q{ruby -e 'puts "Hello"'}]
            }
          }
        }
      end

      it 'load a task with the docker command' do
        is_expected.to eq([
          Djin::Task.new(name: 'default', command: %Q{docker-compose run app sh -c "ruby -e 'puts \"Hello\"'"})
        ])
      end

      context 'with multiples commands' do
        let(:params) do
          {
            'djin_version' => Djin::VERSION,
            'default' => {
              'docker-compose' => {
                'service' => 'app',
                'run' => [
                  %q{ruby -e 'puts "Hello"'},
                  %q{ruby -e 'puts "Bye"'},
                ]
              }
            }
          }
        end

        it 'load a task with the docker command' do
          is_expected.to eq([
            Djin::Task.new(name: 'default',
                           command: %Q{docker-compose run app sh -c "ruby -e 'puts \"Hello\"' && ruby -e 'puts \"Bye\"'"})
          ])
        end
      end

      context 'with expanded run form' do
        let(:params) do
          {
            'djin_version' => Djin::VERSION,
            'default' => {
              'docker-compose' => {
                'service' => 'app',
                'run' => {
                  'commands' => %q{ruby -e 'puts "Hello"'},
                  'options' => '--rm'
                }
              }
            }
          }
        end

        it 'load a task with the docker command' do
          is_expected.to eq([
            Djin::Task.new(name: 'default', command: %Q{docker-compose run --rm app sh -c "ruby -e 'puts \"Hello\"'"})
          ])
        end

        context 'with docker-compose options' do
          let(:params) do
            {
              'djin_version' => Djin::VERSION,
              'default' => {
                'docker-compose' => {
                  'options' => '-f other_compose.yml',
                  'service' => 'app',
                  'run' => {
                    'commands' => %q{ruby -e 'puts "Hello"'},
                    'options' => '--rm'
                  }
                }
              }
            }
          end

          it 'load a task with the docker command' do
            is_expected.to eq([
              Djin::Task.new(name: 'default', command: %Q{docker-compose -f other_compose.yml run --rm app sh -c "ruby -e 'puts \"Hello\"'"})
            ])
          end
        end
      end
    end

    context 'with a depends_on option' do
      let(:params) do
        {
          'djin_version' => Djin::VERSION,
          'one' => {
            'docker' => {
              'image' => 'ruby:2.5',
              'run' => [%q{ruby -e 'puts "Hello"'}]
            }
          },
          'two' => {
            'docker-compose' => {
              'options' => '-f other_compose.yml',
              'service' => 'app',
              'run' => {
                'commands' => %q{ruby -e 'puts "Hello"'},
                'options' => '--rm'
              }
            },
            'depends_on': ['one']
          }
        }
      end

      it 'load a task with the docker command' do
        is_expected.to eq([
          Djin::Task.new(name: 'one',
                         command: %Q{docker run ruby:2.5 sh -c "ruby -e 'puts \"Hello\"'"}),
          Djin::Task.new(name: 'two',
                         command: %Q{docker-compose -f other_compose.yml run --rm app sh -c "ruby -e 'puts \"Hello\"'"},
                         depends_on: ['one'])
        ])
      end
    end

    context 'with invalid configuration' do
      context 'in a docker task' do
        let(:params) do
          {
            'djin_version' => Djin::VERSION,
            'default' => {
              'docker' => {
                'run' => [%q{ruby -e 'puts "Hello"'}]
              }
            }
          }
        end

        it 'exits in error' do
          expect { load! }.to raise_error(described_class::InvalidSyntaxError) do |error|
            expect(error.message).to eq("{:default=>{:depends_on=>[\"image or build param is required for docker tasks\"]}}")
          end
        end
      end
    end

    context 'without djin_version' do
      let(:params) do
        {
          'default' => {
            'docker' => {
              'image' => 'ruby:2.5',
              'run' => [%q{ruby -e 'puts "Hello"'}]
            }
          }
        }
      end

      it 'exits in error' do
        expect { load! }.to raise_error(described_class::MissingVersionError)
      end
    end

    context 'with a bigger djin_version than the actual' do
      let(:version) { Vseries::SemanticVersion.new(Djin::VERSION).up(:patch).to_s }
      let(:params) do
        {
          'djin_version' => version,
          'default' => {
            'docker' => {
              'image' => 'ruby:2.5',
              'run' => [%q{ruby -e 'puts "Hello"'}]
            }
          }
        }
      end

      it 'exits in error' do
        expect { load! }.to raise_error(described_class::VersionNotSupportedError)
      end
    end
  end
end
