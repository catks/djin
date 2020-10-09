# frozen_string_literal: true

RSpec.describe Djin do
  it 'has a version number' do
    expect(Djin::VERSION).not_to be nil
  end

  describe '.load_tasks!' do
    subject(:load_tasks!) { described_class.load_tasks!(path) }

    context 'without djin.yml file' do
      let(:path) { 'not/a/file' }

      it 'exits with a error' do
        expect { load_tasks! }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
          expect(error.message).to eq("[FileNotFoundError] File 'not/a/file' not found")
        end
      end
    end

    context 'without a parameter' do
      subject(:load_tasks!) { described_class.load_tasks! }

      before do
        disable_warnings do
          @temp_argv = ARGV
          ARGV = [].freeze
        end
      end

      after do
        disable_warnings do
          ARGV = @temp_argv
        end
      end

      it 'try to load djin.yml' do
        allow(Djin::ConfigLoader).to receive(:load_files!).with('djin.yml').and_call_original
        allow(Djin::ConfigLoader).to receive(:load_files!).with('djin.yml').and_call_original

        load_tasks!

        expect(Djin::ConfigLoader).to have_received(:load_files!).with('djin.yml')
      end
    end
  end
end
