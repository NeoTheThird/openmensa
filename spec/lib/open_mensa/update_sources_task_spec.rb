require 'spec_helper'

describe OpenMensa::UpdateSourcesTask do
  let(:task) { described_class.new }
  let(:sources) { FactoryBot.create_list :source, 3, meta_url: 'http://example.com/meta.xml' }
  let(:updater) { double('SourceUpdater', sync: true) }

  context '#do' do
    it 'should sync every source' do
      expect(OpenMensa::SourceUpdater).to receive(:new).with(sources[0]).and_return(updater)
      expect(OpenMensa::SourceUpdater).to receive(:new).with(sources[1]).and_return(updater)
      expect(OpenMensa::SourceUpdater).to receive(:new).with(sources[2]).and_return(updater)

      task.do
    end

    it 'should skip sources with archived canteen' do
      sources[1].canteen.update_attributes state: 'archived'
      expect(OpenMensa::SourceUpdater).to receive(:new).with(sources[0]).and_return(updater)
      expect(OpenMensa::SourceUpdater).to_not receive(:new).with(sources[1])
      expect(OpenMensa::SourceUpdater).to receive(:new).with(sources[2]).and_return(updater)

      task.do
    end

    it 'should skip sources without meta url' do
      sources[1].update_attributes meta_url: nil
      expect(OpenMensa::SourceUpdater).to receive(:new).with(sources[0]).and_return(updater)
      expect(OpenMensa::SourceUpdater).to_not receive(:new).with(sources[1])
      expect(OpenMensa::SourceUpdater).to receive(:new).with(sources[2]).and_return(updater)

      task.do
    end
  end
end
