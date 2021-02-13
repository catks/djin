# frozen_string_literal: true

module Djin
  class IncludeContract < Dry::Validation::Contract
    using Djin::ObjectExtensions

    GIT_URI_REGEXP = Regexp.new('(\w+://)(.+@)*([\w\d\.]+)(:[\d]+){0,1}/*(.*)')

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
      key.failure("Invalid git uri in: #{value}") if value.present? && !GIT_URI_REGEXP.match?(value)
    end

    # TODO: Add more validations to file and to restricted unespected keys
  end
end
