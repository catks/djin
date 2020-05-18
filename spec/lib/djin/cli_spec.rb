RSpec.describe Djin::CLI do
  describe described_class::Version do
    let(:instance) { described_class.new }

    it 'prints the djin version' do
      allow(instance).to receive(:puts)

      instance.call

      expect(instance).to have_received(:puts).with(Djin::VERSION)
    end
  end
end

