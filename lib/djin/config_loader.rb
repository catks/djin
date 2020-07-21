# frozen_string_literal: true

module Djin
  class ConfigLoader

    using Djin::HashExtensions

    def self.load(template_file)
      new(template_file).load
    end

    def initialize(template_file)
      @template_file = template_file
    end

    def load
      locals = env.merge(variables)

      rendered_template = Mustache.render(@template_file,
                                          args: args.join(' '),
                                          args?: args.any?,
                                          **locals)
      # TODO: Return a DjinConfig Entity
      yaml_load(rendered_template).except('variables')
    end

    private

    def variables
      @variables ||= yaml_load(@template_file)['variables']&.symbolize_keys || {}
    end

    def args
      index = ARGV.index('--')

      return [] unless index

      ARGV.slice((index + 1)..ARGV.size)
    end

    def env
      @env ||= ENV.to_h.symbolize_keys
    end

    def yaml_load(text)
      YAML.safe_load(text, [], [], true)
    end
  end
end
