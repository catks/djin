# frozen_string_literal: true

require 'pathname'

class TestFile
  def initialize(content)
    @content = content
    # TODO: Investigate why using Djin.root_path is going to the wrong directory in CI
    tempfolder = ENV['TMP_TEST_FILE_FOLDER'] || Djin.root_path.join('tmp').to_s
    @tempfile = File.open(Pathname.new(tempfolder).join("djin_test_#{Time.now.to_i}_#{rand(100)}"), 'w+')
    create
  end

  def to_pathname
    Pathname.new(path)
  end

  def close
    @tempfile.close
    File.delete(path) if File.exist?(path)
  end

  def path
    @tempfile.to_path
  end

  private

  def create
    @tempfile.write(@content)
    @tempfile.rewind
  end
end
