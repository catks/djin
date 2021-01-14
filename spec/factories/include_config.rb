# frozen_string_literal: true

FactoryBot.define do
  factory :include_config, class: Djin::IncludeConfig do
    git { 'http://gitserver/myrepo.git' }
    version { 'master' }
    file { 'test.yml' }
    base_directory { '~/.djin/remote' }
    missing { true }
    context do
      {
        variables: {
          namespace: 'remote:'
        }
      }
    end

    initialize_with { new(attributes) }
  end
end
