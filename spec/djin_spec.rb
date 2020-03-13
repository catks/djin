RSpec.describe Djin do
  it "has a version number" do
    expect(Djin::VERSION).not_to be nil
  end

  describe '.load_tasks!' do
    subject(:load_tasks!) { described_class.load_tasks!(path) }

    context 'without djin.yml file' do
      let(:path) { Pathname.new('not/a/file') }

      it 'exits with a error' do
        expect { load_tasks! }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
          expect(error.message).to eq("Error: djin.yml not found")
        end
      end
    end
  end
end
