# frozen_string_literal: true

module Djin
  class IncludeContract < Dry::Validation::Contract
    using Djin::ObjectExtensions

    GIT_URI_REGEXP = Regexp.new('(\w+://)(.+@)*([\w\d\.]+)(:[\d]+){0,1}/*(.*)')
    GIT_SSH_REGEXP = Regexp.new('(.+@)+([\w\d\.]+):(.*)')
    GIT_FILE_REGEXP = Regexp.new('file://(.*)')

    ContextSchema = Dry::Schema.Params do
      optional(:variables).filled(:hash)
      # TODO: Add the rest
    end

    params do
      optional(:context).filled do
        hash(ContextSchema)
      end
      required(:file).filled(:string)
      optional(:git).filled(:string)
      optional(:version).filled(:string)
    end

    rule(:git) do
      key.failure("Invalid git uri in: #{value}") if value.present? && !valid_git_repository_path?(value)
    end

    # TODO: Add more validations to file and to restricted unespected keys
    #
    private

    def valid_git_repository_path?(path)
      [GIT_URI_REGEXP,
       GIT_SSH_REGEXP,
       GIT_FILE_REGEXP].any? { |regexp| regexp.match?(path) }
    end
  end
end
