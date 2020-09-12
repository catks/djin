# frozen_string_literal: true

require 'tempfile'
require 'pathname'

class TestFile
  def initialize(content)
    @content = content
    @tempfile = Tempfile.new("djin_test_#{Time.now.to_i}")
    create
  end

  def to_pathname
    Pathname.new(path)
  end

  def path
    @tempfile.path
  end

  def recreate
    close
    create
  end

  def close
    @tempfile.close
    @tempfile.unlink
  end

  private

  def create
    @tempfile.write(@content)
    @tempfile.rewind
  end
end
