# frozen_string_literal: true

RSpec.describe Djin::IncludeContract do
  let(:instance) { described_class.new }

  describe 'Include Validation' do
    subject(:validation) { instance.call(include_params) }

    context 'with a local include' do
      context 'with valid params' do
        let(:include_params) do
          {
            'file' => 'my_file',
            'context' => {
              'variables' => {
                'namespace' => 'host1',
                'host' => 'host1.com',
                'ssh_user' => 'my_user'
              }
            }
          }
        end

        it 'is expect to be valid' do
          is_expected.to be_success
        end

        context 'with invalid params' do
          let(:include_params) do
            {
              'filew' => 'my_file',
              'context' => []
            }
          end

          it 'is expected to be invalid' do
            is_expected.to be_a_failure
          end

          it 'returns the errors for the fields' do
            expect(validation.errors.map(&:path)).to eq([%i[context], %i[file]])
          end
        end
      end
    end

    context 'with a remote include' do
      context 'with valid params' do
        let(:include_params) do
          {
            'file' => 'my_file',
            'git' => 'https://gitserver/myrepo.git',
            'version' => '1.1.0',
            'context' => {
              'variables' => {
                'namespace' => 'host1',
                'host' => 'host1.com',
                'ssh_user' => 'my_user'
              }
            }
          }
        end

        it 'is expect to be valid' do
          is_expected.to be_success
        end

        context 'with ssh path' do
          let(:include_params) do
            {
              'file' => 'my_file',
              'git' => 'git@bitbucket.org:vagas/djin_vagas.git',
              'version' => '9.10.0',
              'context' => {
                'variables' => {
                  'namespace' => 'host1',
                  'host' => 'host1.com',
                  'ssh_user' => 'my_user'
                }
              }
            }
          end

          it 'is expect to be valid' do
            is_expected.to be_success
          end
        end

        context 'with a file path' do
          let(:include_params) do
            {
              'file' => 'my_file',
              'git' => 'file:///path/to/repo.git/',
              'version' => '9.80.109',
              'context' => {
                'variables' => {
                  'namespace' => 'host1',
                  'host' => 'host1.com',
                  'ssh_user' => 'my_user'
                }
              }
            }
          end

          it 'is expect to be valid' do
            is_expected.to be_success
          end
        end
      end

      context 'with invalid params' do
        let(:include_params) do
          {
            'file' => [],
            'git' => 'opa',
            'version' => {},
            'context' => {
              'variables' => {
                'namespace' => 'host1',
                'host' => 'host1.com',
                'ssh_user' => 'my_user'
              }
            }
          }
        end

        it 'is expected to be invalid' do
          is_expected.to be_a_failure
        end

        it 'returns the errors for the fields' do
          expect(validation.errors.map(&:path)).to eq([%i[file], %i[version], %i[git]])
        end
      end
    end
  end
end
