# frozen_string_literal: true

RSpec.describe 'Run Tasks', type: :feature do
  context 'with a task to execute' do
    it 'executes the command' do
      run_command('djin hello', path: 'spec/support/fixtures/')

      expected = <<~DESC
        Hello From Djin
      DESC

      expect(command_stdout).to eq(expected)
    end

    context 'with a custom file' do
      it 'executes the command' do
        run_command('djin -f djin.yml hello', path: 'spec/support/fixtures/')

        expected = <<~DESC
          Hello From Djin
        DESC

        expect(command_stdout).to eq(expected)
      end
    end

    context 'with multiple files' do
      it 'executes the command' do
        run_command('djin -f djin.yml -f djin_2.yml hello2', path: 'spec/support/fixtures/')

        expected = <<~DESC
          Hello2
        DESC

        expect(command_stdout).to eq(expected)
      end

      context 'using a variable from other file' do
        xit 'executes the command' do
          run_command('djin -f djin.yml -f variables.yml hello', path: 'spec/support/fixtures/')

          expected = <<~DESC
            Hello From Djin with custom variables file
          DESC

          expect(command_stdout).to eq(expected)
        end
      end
    end

    context 'with a invalid config' do
      it 'return a error' do
        run_command('djin hello', path: 'spec/support/fixtures/invalid/')

        expected = %([InvalidSyntaxError] {:include=>{:context=>["must be filled"], ) +
                   %(:file=>["must be filled"], :version=>["must be filled"], ) +
                   %(:git=>["Invalid git uri in: http:gitserver/myrepo.git"]}}\n)

        expect(command_stderr).to eq(expected)
      end
    end
  end
end
