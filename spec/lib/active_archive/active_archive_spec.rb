# frozen_string_literal: true

require 'spec_helper'

describe ActiveArchive do

  describe '.archive' do
    context 'all records on table with archived_at' do
      it 'to be Time object when soft-deleted' do
        user = User.create!
        user.archive

        expect(user.archived_at.is_a?(Time)).to eq(true)
      end

      it 'to be 1 when soft-deleted' do
        user = User.create!
        user.archive

        expect(User.count).to eq(1)
      end
    end

    context 'all records on table without archived_at' do
      it 'to be 0 when soft-deleted' do
        license = License.create!
        license.archive

        expect(License.count).to eq(0)
      end
    end

    context 'all records on dependent table with archived_at' do
      it 'to be true when soft-deleted' do
        user = User.create!
        Bio.create!(user_id: user.id)
        user.bio.archive

        expect(user.bio.archived?).to eq(true)
      end

      it 'to be 1 when soft-deleted' do
        user = User.create!
        Bio.create!(user_id: user.id)
        user.bio.archive

        expect(Bio.count).to eq(1)
      end
    end

    context 'all records on dependent table without archived_at' do
      it 'to be 0 when soft-deleted' do
        user = User.create!
        License.create!(user_id: user.id)
        user.license.archive

        expect(License.count).to eq(0)
      end
    end

    context 'last record on dependent table with archived_at' do
      it 'to be 2 when soft-deleted' do
        user = User.create!
        2.times { Comment.create!(user_id: user.id) }
        user.comments.last.archive

        expect(Comment.count).to eq(2)
      end

      it 'to be true for each condition' do
        user = User.create!
        2.times { Comment.create!(user_id: user.id) }
        user.comments.last.archive

        expect(Comment.first.unarchived?).to eq(true)
        expect(Comment.last.archived?).to eq(true)
      end
    end

    context 'first record on dependent table with archived_at' do
      it 'to be 2 when soft-deleted' do
        user = User.create!
        2.times { Car.create!(user_id: user.id) }
        user.cars.first.archive

        expect(Car.count).to eq(2)
      end
    end

    context 'all records on parent table with and dependent table without archived_at' do
      it 'to be 0 when soft-deleted' do
        user = User.create!
        car = user.cars.create!
        Insurance.create!(car_id: car.id)
        user.cars.first.archive

        expect(Insurance.count).to eq(0)
      end
    end

    context 'all records on parent table with and dependent table with archived_at' do
      it 'to be 2 when soft-deleted' do
        user = User.create!
        car = user.cars.create!
        2.times { car.drivers.create! }
        user.cars.first.archive

        expect(Driver.archived.count).to eq(2)
      end
    end
  end

  describe '.archive_all' do
    context 'all records on dependent table with archived_at' do
      it 'to be all the proper counts when soft-delete' do
        user = User.create!
        car = user.cars.create!
        2.times { car.drivers.create! }
        Insurance.create(car_id: car.id)

        user.cars.archive_all

        expect(Car.count).to eq(1)
        expect(Driver.count).to eq(2)
        expect(Insurance.count).to eq(0)
      end
    end
  end

  describe '.unarchive' do
    context 'all records on table with archived_at' do
      it 'to be 1 when soft-deleted' do
        user = User.create!
        user.archive
        user.unarchive

        expect(User.count).to eq(1)
      end

      it 'to be nil when soft-deleted' do
        user = User.create!
        user.archive
        user.unarchive

        expect(user.archived_at).to eq(nil)
      end
    end

    context 'all records on table without archived_at' do
      it 'to be 0 when soft-deleted' do
        license = License.create!
        license.archive

        expect(License.count).to eq(0)
      end
    end

    context 'all records on dependent table with archived_at' do
      it 'to be true when soft-deleted' do
        user = User.create!
        Bio.create!(user_id: user.id)
        user.bio.archive
        user.bio.unarchive

        expect(user.bio.unarchived?).to eq(true)
      end
    end

    context 'all records on dependent table with archived_at' do
      it 'to be 2 when soft-deleted' do
        user = User.create!
        2.times { user.cars.create! }
        user.archive
        user.unarchive

        expect(Car.unarchived.count).to eq(2)
      end
    end
  end

  describe '.archival?' do
    context 'with saved_change_to_archived_at?' do
      it 'returns false when archived_at has not changed' do
        user = User.create!

        expect(user.archival?).to eq(false)
      end

      it 'returns true when archived_at changed' do
        user = User.create!
        user.archive

        expect(user.archival?).to eq(true)
      end
    end

    context 'with will_save_change_to_archived_at?' do
      it 'returns true when archived_at changed' do
        user = User.create!
        user.archived_at = Time.now

        expect(user.archival?).to eq(true)
      end
    end

    context 'with destroyed?' do
      it 'returns true when object destroyed' do
        license = License.create!
        license.archive

        expect(license.archival?).to eq(true)
      end
    end
  end

  describe '.unarchival?' do
    context 'with saved_change_to_archived_at?' do
      it 'returns false when archived_at has not changed' do
        user = User.create!

        expect(user.unarchival?).to eq(false)
      end

      it 'returns true when archived_at changed' do
        user = User.create!
        user.archive
        user.unarchive

        expect(user.unarchival?).to eq(true)
      end
    end

    context 'with will_save_change_to_archived_at?' do
      it 'returns true when archived_at changed' do
        user = User.create!(archived_at: Time.now)
        user.archived_at = nil

        expect(user.unarchival?).to eq(true)
      end
    end

    context 'with destroyed?' do
      it 'returns true when object destroyed' do
        license = License.create!

        expect(license.unarchival?).to eq(true)
      end
    end
  end

  describe '.to_archival' do
    it 'to be "Unarchived"' do
      user = User.create!

      expect(user.to_archival).to eq('Unarchived')
    end

    it 'to be "Archived"' do
      user = User.create!
      user.archive

      expect(user.to_archival).to eq('Archived')
    end
  end

  describe '.callbacks' do
    context 'to after_unarchive' do
      it 'to be "after name" for name' do
        user = User.create!
        user.archive

        expect(user.random).to eq(5)
      end
    end

    context 'to before_unarchive' do
      it 'to be "before name" for name' do
        user = User.create!
        user.archive
        user.unarchive

        expect(user.random).to eq(3)
      end
    end
  end

  describe '.counter_cache' do
    context 'increment counters' do
      it 'to be 2 when dependents created' do
        user = User.create!
        2.times { user.cars.create! }

        expect(user.cars_count).to eq(2)
      end
    end

    context 'decrement counters' do
      it 'to be 2 when soft-deleted' do
        user = User.create!
        2.times { user.cars.create! }
        user.cars.last.archive

        expect(user.cars_count).to eq(2)
      end

      it 'to be 1 when perma-deleted' do
        user = User.create!
        2.times { user.cars.create! }
        user.cars.last.destroy

        expect(user.cars_count).to eq(1)
      end
    end
  end

  describe '.dirty_attributes' do
    context 'add archived_at to mutations' do
      it 'to be true for saved_change_to_archived_at?' do
        user = User.create!
        user.archive

        expect(user.saved_change_to_archived_at?).to eq(true)
      end

      it 'to be true for will_save_change_to_archived_at?' do
        user = User.create!
        user.archived_at = Time.now

        expect(user.will_save_change_to_archived_at?).to eq(true)
      end
    end
  end

end
