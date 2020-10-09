# frozen_string_literal: true

module Djin
  ## This class is responsible to handle options that must be evaluated
  #  before the load of tasks in djin file(eg: djin.yml)
  class RootCliParser
    class << self
      def parse!(args = ARGV)
        options = {}

        # TODO: Find a better way to handle -f/--file option,
        #       throw, catch and delete in ARGV are necessary
        #       to only remove the -f/--file option
        #       and bypass everything else to Dry::CLI
        catch(:root_cli_exit) do
          OptionParser.new do |opts|
            opts.on('-f FILE', '--file FILE') do |v|
              options[:files] ||= []
              options[:files] << v
            end

            opts.on('-h', '--help') do
              throw :root_cli_exit
            end
          end.parse(args)
        end

        remove_file_args!(args)
        options
      end

      def remove_file_args!(args)
        file_option = ['-f', '--file']
        args_indexes_to_remove = args.each_with_index.map do |value, index|
          index if (file_option.include?(args[index - 1]) && index.positive?) || file_option.include?(value)
        end.compact

        args_indexes_to_remove.reverse.each { |index| args.delete_at(index) }
      end
    end
  end
end
