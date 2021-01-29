# frozen_string_literal: true

RSpec.describe Djin::RemoteConfigRepository, type: :repository do
  let(:temp_folder) { Djin.root_path.join('tmp').expand_path }
  let(:djin_remote_folder) { temp_folder.join('.djin/remote') }

  let(:instance) { described_class.new(remote_configs, base_path: djin_remote_folder) }

  describe '#fetch_all' do
    def fetch_all
      instance.fetch_all
    end

    let(:repo) do
      TestRemoteRepository.new('myrepo',
                               base_directory: djin_remote_folder,
                               version: version,
                               git_uri: remote_configs.first.git)
    end
    let(:repo2) do
      TestRemoteRepository.new('myrepo2',
                               base_directory: djin_remote_folder,
                               version: version,
                               git_uri: remote_configs.last.git)
    end
    let(:version) { 'master' }

    after do
      repo.delete
      repo2.delete
    end

    context 'when remote config doenst exists' do
      let(:remote_configs) do
        [
          build(:include_config, missing: true, base_directory: djin_remote_folder.to_s)
        ]
      end

      it 'clone repository to remote folder' do
        expect {
          fetch_all
        }.to change { repo.exist? }
          .from(false).to(true)

        expect(repo.join('test.yml').read)
          .to eq(Djin.root_path.join('docker/git_server/repos/myrepo/test.yml').read)
      end

      context 'for multiple repos' do
        let(:remote_configs) do
          [
            build(:include_config, missing: true, base_directory: djin_remote_folder.to_s),
            build(:include_config, missing: true, git: 'http://gitserver/myrepo2.git',
                                   base_directory: djin_remote_folder.to_s)
          ]
        end

        it 'clone repository to remote folder' do
          expect {
            fetch_all
          }.to change { [repo.exist?, repo2.exist?] }
            .from([false, false]).to([true, true])

          expect(repo.join('test.yml').read)
            .to eq(Djin.root_path.join('docker/git_server/repos/myrepo/test.yml').read)

          expect(repo2.join('another_test.yml').read)
            .to eq(Djin.root_path.join('docker/git_server/repos/myrepo2/another_test.yml').read)
        end
      end

      context 'with the same repo reference' do
        let(:remote_configs) do
          [
            build(:include_config, missing: true, base_directory: djin_remote_folder.to_s),
            build(:include_config, missing: true, base_directory: djin_remote_folder.to_s)
          ]
        end

        it 'clone repository to remote folder' do
          expect {
            fetch_all
          }.to change { repo.exist? }
            .from(false).to(true)

          expect(repo.join('test.yml').read)
            .to eq(Djin.root_path.join('docker/git_server/repos/myrepo/test.yml').read)
        end

        it 'try to clone repository once' do
          allow(Git).to receive(:clone).and_call_original

          fetch_all

          expect(Git).to have_received(:clone).once
        end
      end
    end

    context 'when remote config exist' do
      before do
        repo.clone_git_repository
        repo.git.checkout(version, b: true) unless version == 'master'
        repo.git.push('origin', version, f: true)

        repo.add_file('new_file', content: 'New file')

        repo.git.config('user.name', 'Teste Testador')
        repo.git.config('user.email', 'test@email.com')
        repo.git.add('new_file')
        repo.git.commit('New File')
        repo.git.push('origin', version)
        repo.reset_local
      end

      after do
        repo.reset_all
      end

      let(:remote_configs) do
        [
          build(:include_config, missing: false, version: version, base_directory: djin_remote_folder.to_s)
        ]
      end

      it 'update repository' do
        expect {
          fetch_all
        }.to change { repo.join('new_file').exist? }.from(false).to(true)
      end

      context 'with a version with /' do
        let(:version) { 'feature/some_feature' }

        it 'update repository' do
          expect {
            fetch_all
          }.to change { repo.join('new_file').exist? }.from(false).to(true)
        end
      end
    end
  end

  xdescribe '#clear' do
  end
end
