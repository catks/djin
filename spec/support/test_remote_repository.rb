# frozen_string_literal: true

require 'pathname'

class TestRemoteRepository
  def initialize(name, version: 'master', base_directory: Djin.root_path.join('tmp'))
    @name = name
    @version = version
    @base_directory = base_directory
  end

  def to_pathname
    @to_pathname ||= @base_directory.join(folder_name)
  end

  def folder_name
    "#{@name}@#{@version}"
  end

  def create
    to_pathname.mkdir
  end

  def delete
    to_pathname.rmtree
  end

  def add_file(file_path, content:)
    file_full_path = to_pathname.join(file_path)
    file_full_path.dirname.mkpath

    file_full_path.open('w+') do |f|
      f.write(content)
    end
  end
end
