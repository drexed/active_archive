# frozen_string_literal: true

require 'spec_helper'

describe ActiveArchive do

  %i[archive destroy].each do |method|
    describe ".#{method}" do
      context 'all records on table with archived_at' do
        it 'to be Time object when soft-deleted' do
          user = User.create!
          user.send(method)

          expect(user.archived_at.is_a?(Time)).to eq(true)
        end

        it 'to be 1 when soft-deleted' do
          user = User.create!
          user.send(method)

          expect(User.count).to eq(1)
        end

        it 'to be 0 when perma-deleted' do
          user = User.create!
          user.send(method, :force)

          expect(User.count).to eq(0)
        end
      end

      context 'all records on table without archived_at' do
        it 'to be 0 when soft-deleted' do
          license = License.create!
          license.send(method)

          expect(License.count).to eq(0)
        end

        it 'to be 0 when perma-deleted' do
          license = License.create!
          license.send(method, :force)

          expect(License.count).to eq(0)
        end
      end

      context 'all records on dependent table with archived_at' do
        it 'to be true when soft-deleted' do
          user = User.create!
          Bio.create!(user_id: user.id)
          user.bio.send(method)

          expect(user.bio.archived?).to eq(true)
        end

        it 'to be 1 when soft-deleted' do
          user = User.create!
          Bio.create!(user_id: user.id)
          user.bio.send(method)

          expect(Bio.count).to eq(1)
        end

        it 'to be 0 when perma-deleted' do
          user = User.create!
          Bio.create!(user_id: user.id)
          user.bio.send(method, :force)

          expect(Bio.count).to eq(0)
        end
      end

      context 'all records on dependent table without archived_at' do
        it 'to be 0 when soft-deleted' do
          user = User.create!
          License.create!(user_id: user.id)
          user.license.send(method)

          expect(License.count).to eq(0)
        end

        it 'to be 0 when perma-deleted' do
          user = User.create!
          License.create!(user_id: user.id)
          user.license.send(method, :force)

          expect(License.count).to eq(0)
        end
      end

      context 'last record on dependent table with archived_at' do
        it 'to be 2 when soft-deleted' do
          user = User.create!
          2.times { Comment.create!(user_id: user.id) }
          user.comments.last.send(method)

          expect(Comment.count).to eq(2)
        end

        it 'to be 1 when perma-deleted' do
          user = User.create!
          2.times { Comment.create!(user_id: user.id) }
          user.comments.last.send(method, :force)

          expect(Comment.count).to eq(1)
        end

        it 'to be true for each condition' do
          user = User.create!
          2.times { Comment.create!(user_id: user.id) }
          user.comments.last.send(method)

          expect(Comment.first.unarchived?).to eq(true)
          expect(Comment.last.archived?).to eq(true)
        end
      end

      context 'first record on dependent table with archived_at' do
        it 'to be 2 when soft-deleted' do
          user = User.create!
          2.times { Car.create!(user_id: user.id) }
          user.cars.first.send(method)

          expect(Car.count).to eq(2)
        end

        it 'to be 1 when perma-deleted' do
          user = User.create!
          2.times { Car.create!(user_id: user.id) }
          user.cars.first.send(method, :force)

          expect(Car.count).to eq(1)
        end
      end

      context 'all records on parent table with and dependent table without archived_at' do
        it 'to be 0 when soft-deleted' do
          user = User.create!
          car = user.cars.create!
          Insurance.create!(car_id: car.id)
          user.cars.first.send(method)

          expect(Insurance.count).to eq(0)
        end

        it 'to be 0 when perma-deleted' do
          user = User.create!
          car = user.cars.create!
          Insurance.create!(car_id: car.id)
          user.cars.first.send(method, :force)

          expect(Insurance.count).to eq(0)
        end
      end

      context 'all records on parent table with and dependent table with archived_at' do
        it 'to be 2 when soft-deleted' do
          user = User.create!
          car = user.cars.create!
          2.times { car.drivers.create! }
          user.cars.first.send(method)

          expect(Driver.archived.count).to eq(2)
        end

        it 'to be 0 when perma-deleted' do
          user = User.create!
          car = user.cars.create!
          2.times { car.drivers.create! }
          user.cars.first.send(method, :force)

          expect(Driver.count).to eq(0)
        end
      end
    end

    describe ".#{method}_all(!)" do
      context 'all records on dependent table with archived_at' do
        it 'to be all the proper counts when soft-delete' do
          user = User.create!
          car = user.cars.create!
          2.times { car.drivers.create! }
          Insurance.create(car_id: car.id)

          user.cars.send("#{method}_all")

          expect(Car.count).to eq(1)
          expect(Driver.count).to eq(2)
          expect(Insurance.count).to eq(0)
        end
      end

      context 'all records on dependent table with archived_at' do
        it 'to be all the proper counts when perma-delete' do
          user = User.create!
          car = user.cars.create!
          2.times { car.drivers.create! }
          Insurance.create(car_id: car.id)

          user.cars.send("#{method}_all!")

          expect(Car.count).to eq(0)
          expect(Driver.count).to eq(0)
          expect(Insurance.count).to eq(0)
        end
      end
    end
  end

  describe '.delete_all' do
    context 'all records on dependent table with archived_at' do
      it 'to be all the proper counts when perma-delete' do
        user = User.create!
        car = user.cars.create!
        2.times { car.drivers.create! }
        Insurance.create(car_id: car.id)

        user.cars.delete_all

        expect(Car.count).to eq(0)
        expect(Driver.count).to eq(2)
        expect(Insurance.count).to eq(1)
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
      user.destroy

      expect(user.to_archival).to eq('Archived')
    end
  end

  # TODO: add counter cache test

  %i[unarchive undestroy].each do |method|
    describe ".#{method}" do
      context 'all records on table with archived_at' do
        it 'to be 1 when soft-deleted' do
          user = User.create!
          user.archive
          user.send(method)

          expect(User.count).to eq(1)
        end

        it 'to be nil when soft-deleted' do
          user = User.create!
          user.archive
          user.send(method)

          expect(user.archived_at).to eq(nil)
        end

        it 'to raise error when perma-deleted' do
          user = User.create!
          user.archive(:force)

          expect { user.send(method) }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'all records on table without archived_at' do
        it 'to be 0 when soft-deleted' do
          license = License.create!
          license.archive

          expect(License.count).to eq(0)
        end

        it 'to be 0 when perma-deleted' do
          license = License.create!
          license.archive(:force)

          expect(License.count).to eq(0)
        end

        it 'to raise error when perma-deleted' do
          license = License.create!
          license.archive(:force)

          expect { license.send(method) }.to raise_error(ActiveRecord::RecordNotFound)
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

        it 'to raise error when perma-deleted' do
          user = User.create!
          Bio.create!(user_id: user.id)
          user.bio.archive(:force)

          expect { user.bio.send(method) }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'all records on dependent table with archived_at' do
        it 'to be 2 when soft-deleted' do
          user = User.create!
          2.times { user.cars.create! }
          user.archive
          user.send(method)

          expect(Car.unarchived.count).to eq(2)
        end


        it 'to be 0 when perma-deleted' do
          user = User.create!
          2.times { user.cars.create! }
          user.archive(:force)

          expect(Car.unarchived.count).to eq(0)
        end
      end
    end
  end

  describe '.dirty_attributes' do
    context 'add archived_at to mutations' do
      it 'to be true for changes' do
        user = User.create!
        user.archive

        expect(user.changes.keys.include?('archived_at')).to eq(true)
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
        user.cars.last.archive(:force)

        expect(user.cars_count).to eq(1)
      end
    end
  end

end
