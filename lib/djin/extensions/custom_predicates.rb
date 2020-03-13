module Djin
  module CustomPredicates
    refine Dry::Logic::Predicates::Methods do
      def is_one_of?(value, *options)
        options.map do |option|
          return option.call(value) if respond_to?(:call)

          value.is_a?(option)
        end.any?
      end
    end

    refine Dry::Logic::Predicates do
      extend Dry::Logic::Predicates::Methods
    end
  end
end

