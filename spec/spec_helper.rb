# frozen_string_literal: true

require 'bundler/setup'
require 'byebug'
require 'factory_bot'

require_relative 'support/test_file'
require_relative 'support/test_remote_repository'
require_relative 'support/helpers'

require 'simplecov'
SimpleCov.start

require 'djin'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(type: :feature) do
    @djin_installation ||= begin
                             require 'bundler/gem_tasks'
                             Rake::Task['install'].invoke
                             require 'open3'
                           end
  end

  config.before(:suite) do
    FactoryBot.find_definitions
  end

  config.include(Helpers)
  config.include FactoryBot::Syntax::Methods
end
