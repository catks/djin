# frozen_string_literal: true

RSpec.describe 'remote-config subcommand', type: :feature do
  let(:temp_folder) { Djin.root_path.join('tmp').expand_path }
  let(:djin_remote_folder) { temp_folder.join('.djin/remote') }

  describe 'djin remote-config fetch' do
    def fetch
      run_command('djin remote-config fetch',
                  path: 'spec/support/fixtures/remote_tasks',
                  envs: { HOME: temp_folder.to_s })
    end

    let(:repo) { TestRemoteRepository.new('myrepo', base_directory: djin_remote_folder) }

    after do
      repo.delete
    end

    context 'when remote config doenst exists' do
      before do
        repo.delete
      end

      it 'clone repository to remote folder' do
        expect {
          _, err = fetch
          puts err
        }.to change { repo.exist? }
          .from(false).to(true)

        expect(repo.join('test.yml').read)
          .to eq(Djin.root_path.join('docker/git_server/repos/myrepo/test.yml').read)
      end
    end

    context 'when remote config exist' do
      before do
        fetch

        repo = TestRemoteRepository.new('myrepo', base_directory: djin_remote_folder)

        repo.add_file('new_file', content: 'New file')

        repo.git.config('user.name', 'Teste Testador')
        repo.git.config('user.email', 'test@email.com')
        repo.git.add('new_file')
        repo.git.commit('New File')
        repo.git.push
        repo.reset_local
      end

      after do
        repo.reset_all
      end

      it 'update repository' do
        expect {
          fetch
        }.to change { repo.join('new_file').exist? }.from(false).to(true)
      end
    end
  end
end
