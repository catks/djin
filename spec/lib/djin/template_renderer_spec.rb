# frozen_string_literal: true

RSpec.describe Djin::TemplateRenderer do
  describe '.render' do
    subject { described_class.render(template) }

    context 'with a template without custom values' do
      let(:template) do
        {
          'djin_version' => Djin::VERSION,
          'default' => {
            'docker' => {
              'image' => 'ruby:2.5',
              'run' => [%q(ruby -e 'puts "Hello"')]
            }
          }
        }.to_yaml
      end

      it 'returns the same string' do
        is_expected.to eq(template)
      end
    end

    context 'with custom values for args' do
      let(:template) do
        {
          'djin_version' => Djin::VERSION,
          'default' => {
            'docker' => {
              'image' => 'ruby:2.5',
              'run' => ['rubocop {{args}}']
            }
          }
        }.to_yaml
      end

      let(:command_args) { ['some:task', '--', '-a'] }

      it 'returns a string with rendered args' do
        stub_const('ARGV', command_args)

        expected_rendered_template = {
          'djin_version' => Djin::VERSION,
          'default' => {
            'docker' => {
              'image' => 'ruby:2.5',
              'run' => ['rubocop -a']
            }
          }
        }.to_yaml
        is_expected.to eq(expected_rendered_template)
      end
    end

    context 'when using args and args?' do
      let(:template) do
        {
          'djin_version' => Djin::VERSION,
          'default' => {
            'docker' => {
              'image' => 'some_image',
              'run' => ['echo "Hi{{#args?}}, I Have args{{/args?}}"']
            }
          }
        }.to_yaml
      end

      context 'with args' do
        let(:command_args) { ['some:task', '--', '-a'] }

        it 'returns a string folowwinf the consitional' do
          stub_const('ARGV', command_args)

          expected_rendered_template = {
            'djin_version' => Djin::VERSION,
            'default' => {
              'docker' => {
                'image' => 'some_image',
                'run' => ['echo "Hi, I Have args"']
              }
            }
          }.to_yaml
          is_expected.to eq(expected_rendered_template)
        end
      end

      context 'without args' do
        let(:command_args) { [] }

        it 'returns a string folowwinf the consitional' do
          stub_const('ARGV', command_args)

          expected_rendered_template = {
            'djin_version' => Djin::VERSION,
            'default' => {
              'docker' => {
                'image' => 'some_image',
                'run' => ['echo "Hi"']
              }
            }
          }.to_yaml
          is_expected.to eq(expected_rendered_template)
        end
      end
    end

    context 'with environment variables' do
      let(:template) do
        {
          'djin_version' => Djin::VERSION,
          'default' => {
            'docker' => {
              'image' => 'some_image',
              'run' => ['ls {{#MULTIPLE_FILES}}{{FILES}}{{/MULTIPLE_FILES}}']
            }
          }
        }.to_yaml
      end

      let(:command_args) { ['some:task', '--', '-a'] }
      let(:files) { 'test test2' }

      before do
        ENV['FILES'] = files
        ENV['MULTIPLE_FILES'] = 'true'
      end

      it 'returns a string with rendered args' do
        stub_const('ARGV', command_args)

        expected_rendered_template = {
          'djin_version' => Djin::VERSION,
          'default' => {
            'docker' => {
              'image' => 'some_image',
              'run' => ['ls test test2']
            }
          }
        }.to_yaml
        is_expected.to eq(expected_rendered_template)
      end
    end
  end
end
