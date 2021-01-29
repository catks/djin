# frozen_string_literal: true

require 'pathname'

class TestRemoteRepository
  def initialize(name, version: 'master', base_directory: nil, git_uri: nil)
    @name = name
    @version = version
    @base_directory = base_directory || Pathname.new(ENV['TMP_TEST_FILE_FOLDER'] || Djin.root_path.join('tmp').to_s)
    @git_uri = git_uri
  end

  def join(*args)
    to_pathname.join(*args)
  end

  def reset_all
    reset_local
    # git.push(force: true) fails as it tries to use ssh
    `cd #{to_pathname} && git push --force origin #{@version}`
  end

  def reset_local
    git.reset_hard('HEAD~1')
  end

  def exist?
    to_pathname.exist?
  end

  def to_pathname
    @to_pathname ||= @base_directory.join(folder_name)
  end

  def git
    @git ||= Git.open(to_pathname.to_s)
  end

  def clone_git_repository
    raise 'Missing git uri to clone' unless @git_uri

    @git = Git.clone(@git_uri, to_pathname.to_s)
  end

  def folder_name
    "#{@name}@#{@version}"
  end

  def create
    to_pathname.mkdir
  end

  def delete
    to_pathname.rmtree if to_pathname.exist?
  end

  def add_file(file_path, content:)
    file_full_path = to_pathname.join(file_path)
    file_full_path.dirname.mkpath

    file_full_path.open('w+') do |f|
      f.write(content)
    end
  end
end
