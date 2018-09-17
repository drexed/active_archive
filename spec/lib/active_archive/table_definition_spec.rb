# frozen_string_literal: true

require 'spec_helper'

describe ActiveRecord::ConnectionAdapters::TableDefinition do
  let(:user) { User.create! }
  let(:license) { License.create! }

  describe '.timestamps archive: true' do
    it 'to be true for table with archived_at' do
      expect(user.archivable?).to eq(true)
    end

    it 'to be false for table without archived_at' do
      expect(license.archivable?).to eq(false)
    end
  end
end
