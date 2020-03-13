RSpec.describe Djin::Executor do
  let(:instance) { described_class.new }

  describe '#call' do
    subject(:call) { instance.call(*tasks) }

    before { allow(instance).to receive(:system) }

    context 'with one task' do
      let(:tasks) { [Djin::Task.new(name: 'test', command: 'echo test')] }

      context 'without build_command' do
        it 'executes the command' do
          call

          expect(instance).to have_received(:system).once.with(tasks.first.command)
        end
      end

      context 'with build_command' do
        let(:tasks) { [Djin::Task.new(name: 'test', build_command: 'docker build . -t test',  command: 'docker run test')] }

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
          Djin::Task.new(name: 'test2', build_command: 'docker build . -t test2',  command: 'docker run test2')
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
    end
  end
end
