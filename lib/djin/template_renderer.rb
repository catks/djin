module Djin
  class TemplateRenderer
    def self.render(template_file)
      new(template_file).render
    end

    def initialize(template_file)
      @template_file = template_file
    end

    def render
      Mustache.render(@template_file,
                      args: args.join(' '),
                      args?: args.any?,
                      **env)
    end

    private

    def args
      index = ARGV.index('--')

      return [] unless index

      ARGV.slice((index + 1)..ARGV.size)
    end

    def env
      @env ||= ENV.to_h.map { |k, v| [k.to_sym, v] }.to_h
    end
  end
end
