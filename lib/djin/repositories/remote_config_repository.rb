# frozen_string_literal: true

module Djin
  class RemoteConfigRepository
    attr_accessor :base_path

    def initialize(remote_configs, base_path: Pathname.new('~/.djin/remote'), stderr: Djin.stderr)
      @remote_configs = remote_configs
      @base_path = base_path
      @stderr = stderr
    end

    def add(remote_config)
      remote_configs << remote_config
    end

    def find(**filters)
      remote_configs.select do |remote_config|
        filters.reduce(true) do |memo, (filter_key, filter_value)|
          memo && remote_config.public_send(filter_key) == filter_value
        end
      end
    end

    def fetch_all
      remote_configs_by_folders.each do |rc|
        git_folder = base_path.join(rc.folder_name).expand_path

        # TODO: Extract STDEER Output, maybe publishing events and subscribing a observer for the logs.
        stderr.puts "Remote Path: #{base_path.expand_path}"

        git_repo = rc.missing? ? clone_repo(git_folder, rc) : fetch_repo(git_folder, rc)

        stderr.puts "Checking out to '#{rc.version}'"
        git_repo.checkout(rc.version)
        git_repo.pull
      end
    end

    def clear
      remote_configs_by_folders.each do |rc|
        git_folder = base_path.join(rc.folder_name)

        stderr.puts "Removing #{rc.folder_name} repository..."
        `rm -rf #{git_folder}`
      end
    end

    def clear_all
      remove_remote_folder
    end

    def remote_configs
      @remote_configs ||= []
    end

    private

    attr_accessor :stderr

    def remote_configs_by_folders
      @remote_configs_by_folders ||= remote_configs
                                     .group_by(&:folder_name)
                                     .values
                                     .map(&:first)
    end

    def remove_remote_folder
      stderr.puts "Removing #{base_path}..."
      `rm -rf #{base_path}`
    end

    def clone_repo(git_folder, remote_config)
      stderr.puts "Missing #{remote_config.folder_name} repository, cloning in #{git_folder}"
      Git.clone(remote_config.git.to_s, git_folder.to_s, branch: remote_config.version)
    end

    def fetch_repo(git_folder, remote_config)
      stderr.puts "#{remote_config.git} repository already cloned, fetching..."
      git_repo = Git.open(git_folder)
      git_repo.fetch

      git_repo
    end
  end
end
