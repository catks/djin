# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'djin/version'

Gem::Specification.new do |spec|
  spec.name          = 'djin'
  spec.version       = Djin::VERSION
  spec.authors       = ['Carlos Atkinson']
  spec.email         = ['carlos.atks@gmail.com']

  spec.summary       = 'djin is a make-like utility for docker containers'
  spec.homepage      = 'https://github.com/catks/djin'
  spec.license       = 'MIT'

  # spec.metadata["homepage_uri"] = spec.homepage
  # spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features|docker)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'dry-cli', '~> 0.6.0'
  spec.add_dependency 'dry-configurable', '~> 0.9.0'
  spec.add_dependency 'dry-container', '~> 0.7.0'
  spec.add_dependency 'dry-core', '~> 0.6.0'
  spec.add_dependency 'dry-equalizer', '~> 0.3.0'
  spec.add_dependency 'dry-inflector', '~> 0.1.0'
  spec.add_dependency 'dry-schema', '~> 1.6.0'
  spec.add_dependency 'dry-struct', '~> 1.3.0'
  spec.add_dependency 'dry-validation', '= 1.5.1'
  spec.add_dependency 'git', '~> 1.8.1'
  spec.add_dependency 'mustache', '~> 1.1.1'
  spec.add_dependency 'vseries', '~> 0.1.0'
  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'byebug'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'simplecov', '~> 0.17.0'
end
