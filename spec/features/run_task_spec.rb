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

    context 'with a task with depends_on' do
      it 'execute the dependencies before running current task' do
        run_command('djin task_1_and_2', path: 'spec/support/fixtures/depends_on/')

        expected_stdout = <<~DESC
          Task 1 Executed
          Task 2 Executed
          Executed Both Tasks
        DESC

        expect(command_stdout).to eq(expected_stdout)
      end

      context 'with a breaking dependent task' do
        it 'executes the command' do
          run_command('djin broken_depends', path: 'spec/support/fixtures/depends_on/')

          expected_stdout = <<~DESC
            I will break you
          DESC

          expect(command_stdout).to eq(expected_stdout)

          expected_stderr = <<~DESC
            sh: invalid_command_here: not found
            [TaskError] Task `broken` failed
          DESC

          expect(command_stderr).to eq(expected_stderr)
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
