# frozen_string_literal: true

require 'spec_helper'

describe ActiveArchive::Methods do

  describe '.archivable?' do
    it 'to be true for table with archived_at' do
      user = User.create!

      expect(user.archivable?).to eq(true)
    end

    it 'to be false for table with archived_at' do
      license = License.create!

      expect(license.archivable?).to eq(false)
    end
  end

  describe '.archive_all' do
    it 'to be 0 when table is unarchivable and everything is perma-deleted' do
      3.times { License.create! }
      License.archive_all

      expect(License.count).to eq(0)
    end

    it 'to be 3 when table is archivable and is soft-deleted' do
      3.times { User.create! }
      User.archive_all

      expect(User.archived.count).to eq(3)
    end

    it 'to be 2 when parent table is archivable and dependent table is soft-deleted' do
      user = User.create!
      car = user.cars.create!
      2.times { car.drivers.create! }
      User.archive_all

      expect(Driver.archived.count).to eq(2)
    end
  end

  describe '.unarchive_all' do
    it 'to be 0 when table is unarchivable and everything is perma-deleted and revived' do
      3.times { License.create! }
      License.archive_all
      License.unarchive_all

      expect(License.count).to eq(0)
    end

    it 'to be 3 when table is archivable and is soft-deleted and revived' do
      3.times { User.create! }
      User.archive_all
      User.unarchive_all

      expect(User.unarchived.count).to eq(3)
    end

    it 'to be 2 when parent table is archivable and dependent table is soft-deleted and revived' do
      user = User.create!
      car = user.cars.create!
      2.times { car.drivers.create! }
      User.archive_all
      User.unarchive_all

      expect(Driver.unarchived.count).to eq(2)
    end
  end

end
