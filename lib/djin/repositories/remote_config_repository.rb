# frozen_string_literal: true

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
    remote_configs.each do |rc|
      git_folder = base_path.join(rc.folder_name)

      # TODO: Extract Git logic
      # TODO: Extract STDEER Output, maybe publishing events in the repository and subscribing a observer for the logs.
      if rc.missing?
        stderr.puts "Missing #{rc.folder_name} repository, cloning in #{base_path}"
        `git clone --progress #{rc.git} #{git_folder}`
      else
        stderr.puts "#{rc.name} repository already cloned, fetching..."
        `cd #{git_folder} && git fetch`
      end

      if `cd #{git_folder} && git branch`.split.last == rc.version
        stderr.puts "Pulling changes for '#{rc.version}'"
        `cd #{git_folder} && git pull origin #{rc.version}`
      else
        stderr.puts "Checking out to '#{rc.version}'"
        `cd #{git_folder} && git checkout #{rc.version}`
      end
    end
  end

  def clear
    remote_configs.each do |rc|
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

  def remove_remote_folder
    stderr.puts "Removing #{base_path}..."
    `rm -rf #{base_path}`
  end
end
