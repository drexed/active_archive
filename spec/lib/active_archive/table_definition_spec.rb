require 'spec_helper'

describe ActiveRecord::ConnectionAdapters::TableDefinition do
  before do
    3.times { User.create! }
    3.times { License.create! }
  end

  context '#archived_at' do
    it 'to be true' do
      expect(User.first.archivable?).to eq(true)
      expect(License.first.unarchivable?).to eq(true)
    end

    it 'to be false' do
      expect(User.first.unarchivable?).to eq(false)
      expect(License.first.archivable?).to eq(false)
    end
  end
end
