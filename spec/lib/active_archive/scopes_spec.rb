# frozen_string_literal: true

require 'spec_helper'

describe ActiveArchive::Scopes do
  before do
    3.times { User.create! }
    6.times { User.create!.archive }
  end

  describe '.archived' do
    it 'to be 6 archived users' do
      expect(User.archived.count).to eq(6)
    end
  end

  describe '.unarchived' do
    it 'to be 3 unarchived users' do
      expect(User.unarchived.count).to eq(3)
    end
  end
end
