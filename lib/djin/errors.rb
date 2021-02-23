# frozen_string_literal: true

module Djin
  InvalidConfigurationError = Class.new(StandardError)
  InvalidConfigFileError = Class.new(InvalidConfigurationError)
  MissingVersionError = Class.new(InvalidConfigurationError)
  VersionNotSupportedError = Class.new(InvalidConfigurationError)
  InvalidSyntaxError = Class.new(InvalidConfigurationError)
  FileNotFoundError = Class.new(InvalidConfigurationError)

  TaskError = Class.new(StandardError)
end
