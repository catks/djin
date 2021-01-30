# frozen_string_literal: true

RSpec.describe '-v option', type: :feature do
  context 'without a task to execute' do
    it 'returns the help' do
      run_command('djin -v')

      expect(command_stdout.chomp).to eq(Djin::VERSION)
    end
  end
end
