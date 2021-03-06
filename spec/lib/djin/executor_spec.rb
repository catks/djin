# frozen_string_literal: true

RSpec.describe Djin::Executor do
  let(:instance) { described_class.new(task_repository: task_repository) }
  let(:task_repository) { TaskRepository.new }

  describe '#call' do
    subject(:call) { instance.call(*tasks) }

    before { allow(instance).to receive(:system).and_return(true) }

    context 'with one task' do
      let(:tasks) { [Djin::Task.new(name: 'test', command: 'echo test')] }

      context 'without build_command' do
        it 'executes the command' do
          call

          expect(instance).to have_received(:system).once.with(tasks.first.command)
        end
      end

      context 'with build_command' do
        let(:tasks) do
          [Djin::Task.new(name: 'test',
                          build_command: 'docker build . -t test',
                          command: 'docker run test')]
        end

        it 'executes the build command' do
          call

          expect(instance).to have_received(:system).with(tasks.first.build_command).once
        end
        it 'executes the command' do
          call

          expect(instance).to have_received(:system).with(tasks.first.command).once
        end
      end
    end

    context 'with multiple tasks' do
      let(:tasks) do
        [
          Djin::Task.new(name: 'test', build_command: 'docker build . -t test',  command: 'docker run test'),
          Djin::Task.new(name: 'test2', build_command: 'docker build . -t test2', command: 'docker run test2')
        ]
      end

      it 'executes the build commands' do
        call

        tasks.each do |task|
          expect(instance).to have_received(:system).with(task.build_command).once
        end
      end

      it 'executes the commands' do
        call

        tasks.each do |task|
          expect(instance).to have_received(:system).with(task.command).once
        end
      end

      context 'with a task with dependencies' do
        before do
          task_repository.add(*configured_tasks)
        end

        let(:configured_tasks) do
          [
            Djin::Task.new(name: 'test', build_command: 'docker build . -t test', command: 'docker run test'),
            Djin::Task.new(name: 'test1', build_command: 'docker build . -t test1', command: 'docker run test1'),
            Djin::Task.new(name: 'test2', build_command: 'docker build . -t test2',
                           command: 'docker run test2', depends_on: %w[test test1])
          ]
        end

        let(:tasks) { [configured_tasks.last] }

        it 'executes the build commands' do
          call

          tasks.each do |task|
            expect(instance).to have_received(:system).with(task.build_command).once
          end
        end

        it 'executes the commands' do
          call

          tasks.each do |task|
            expect(instance).to have_received(:system).with(task.command).once
          end
        end

        context 'without command' do
          let(:configured_tasks) do
            [
              Djin::Task.new(name: 'test', build_command: 'docker build . -t test', command: 'docker run test'),
              Djin::Task.new(name: 'test1', build_command: 'docker build . -t test1', command: 'docker run test1'),
              Djin::Task.new(name: 'test2', depends_on: %w[test test1])
            ]
          end

          let(:tasks) { [configured_tasks.last] }

          it 'executes the dependent tasks build commands' do
            call

            configured_tasks.select(&:build_command).each do |task|
              expect(instance).to have_received(:system).with(task.build_command).once
            end
          end

          it 'executes the dependent tasks commands' do
            call

            configured_tasks.select(&:command).each do |task|
              expect(instance).to have_received(:system).with(task.command).once
            end
          end

          it 'doesnt execute a nil command' do
            call

            expect(instance).to_not have_received(:system).with(tasks.first.command)
          end

          context 'when a subcommand fail' do
            before { allow(instance).to receive(:system).with(configured_tasks.first.command).and_return(false) }

            it 'executes the first dependent task' do
              call rescue Djin::TaskError

              expect(instance).to have_received(:system).with(configured_tasks.first.build_command).once
              expect(instance).to have_received(:system).with(configured_tasks.first.command).once
              expect(instance).to have_received(:system).twice
            end
          end
        end
      end
    end
  end
end
