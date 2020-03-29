module Djin
  class TaskContract < Dry::Validation::Contract
    NOT_EMPTY = -> (value) { ! value.empty? }
    OK = -> (_) { true }

    BuildSchema = Dry::Schema.Params do
      required(:context).filled(:string)
      required(:options).filled(:string)
    end

    RunSchema = Dry::Schema.Params do
      required(:commands).filled
      required(:options).filled(:string)
    end

    DockerSchema = Dry::Schema.Params do
      optional(:image).maybe(:string)
      optional(:build)
      required(:run).filled
    end

    DockerComposeSchema = Dry::Schema.Params do
      required(:service).filled(:string)
      optional(:options).filled(:string)
      required(:run).filled
    end

    params do
      optional(:docker).filled do
        hash(DockerSchema)
      end
      optional(:"docker-compose").filled do
        hash(DockerComposeSchema)
      end

      optional(:depends_on).each(:str?)
    end

    rule(:docker, :"docker-compose", :depends_on) do
      key.failure('docker, docker-compose or depends_on key is required') unless values[:docker] || values[:"docker-compose"] || values[:depends_on]
    end

    rule(:depends_on, :'docker-compose',docker: [:image, :build])  do
      key.failure('image or build param is required for docker tasks') unless values.dig(:docker, :image) || values.dig(:docker, :build) || values[:'docker-compose'] || values[:depends_on]
    end

    rule(docker: :build) do
      result, errors = validate_for(value, Hash => BuildSchema, String => NOT_EMPTY, NilClass => OK)

      key.failure(errors) unless result
    end

    rule(:'docker-compose' => :run) do
      result, errors = validate_for(value, Hash => RunSchema, Array => NOT_EMPTY, NilClass => OK)

      key.failure(errors) unless result
    end

    rule(docker: :run) do
      result, errors = validate_for(value, Hash => RunSchema, Array => NOT_EMPTY, NilClass => OK)

      key.failure(errors) unless result
    end

    private

    def validate_for(value, validations)
      validations.default_proc = proc { proc { false } }

      result = validations[value.class].call(value)
      return [result, nil] if result == true
      return [result, "invalid #{value.class}"] if result == false

      [result.success?, result.errors.messages.join]
    end
  end
end
