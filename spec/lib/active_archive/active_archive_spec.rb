require 'spec_helper'

describe ActiveArchive do

  describe '#archive' do
    context 'user.archive' do
      it 'to be 1' do
        user = User.create!
        user.archive

        expect(User.count).to eq(1)
      end

      it 'to not be nil' do
        user = User.create!
        user.archive

        expect(user.archived_at).not_to eq(nil)
      end
    end

    context 'user.archive(:force)' do
      it 'to be 0' do
        user = User.create!
        user.archive(:force)

        expect(User.count).to eq(0)
      end
    end

    context 'user.bio.archive' do
      it 'to be true' do
        user = User.create!
        Bio.create!(user_id: user.id)
        user.bio.archive

        expect(user.bio.archived?).to eq(true)
      end

      it 'to be 0' do
        user = User.create!
        Bio.create!(user_id: user.id)
        user.bio.archive(:force)

        expect(Bio.count).to eq(0)
      end
    end

    context 'license.archive' do
      it 'to be 0' do
        license = License.create!
        license.archive

        expect(License.count).to eq(0)
      end
    end

    context 'user.license.archive' do
      it 'to be 0' do
        user = User.create!
        License.create!(user_id: user.id)
        user.license.archive

        expect(License.count).to eq(0)
      end
    end

    context 'user.license.archive(:force)' do
      it 'to be 0' do
        user = User.create!
        License.create!(user_id: user.id)
        user.license.archive(:force)

        expect(License.count).to eq(0)
      end
    end

    context 'user.comments.last.archive' do
      it 'to be 2' do
        user = User.create!
        2.times { Comment.create!(user_id: user.id) }
        user.comments.last.archive

        expect(Comment.count).to eq(2)
      end

      it 'to be true' do
        user = User.create!
        2.times { Comment.create!(user_id: user.id) }
        user.comments.last.archive

        expect(Comment.first.unarchived?).to eq(true)
        expect(Comment.last.archived?).to eq(true)
      end
    end

    context 'user.cars.first.archive' do
      it 'to be 1' do
        user = User.create!
        user.cars.create!
        user.cars.first.archive

        expect(Car.count).to eq(1)
      end

      it 'to be 0' do
        user = User.create!
        car = user.cars.create!
        Insurance.create!(car_id: car.id)
        user.cars.first.archive

        expect(Insurance.count).to eq(0)
      end

      it 'to be 2' do
        user = User.create!
        car = user.cars.create!
        2.times { car.drivers.create! }
        user.cars.first.archive

        expect(Driver.count).to eq(2)
      end

      it 'to be 0' do
        user = User.create!
        car = user.cars.create!
        2.times { car.drivers.create! }
        user.cars.first.archive(:force)

        expect(Driver.count).to eq(0)
      end
    end

    context 'user.cars.first.archive' do
      it 'to be 0' do
        user = User.create!
        car = user.cars.create!
        Insurance.create!(car_id: car.id)
        user.cars.first.archive(:force)

        expect(Car.count).to eq(0)
        expect(Insurance.count).to eq(0)
      end
    end
  end

  describe '#destroy' do
    context 'user.destroy' do
      it 'to be 1' do
        user = User.create!
        user.destroy

        expect(User.count).to eq(1)
      end

      it 'to not be nil' do
        user = User.create!
        user.destroy

        expect(user.archived_at).not_to eq(nil)
      end
    end

    context 'user.destroy(:force)' do
      it 'to be 0' do
        user = User.create!
        user.destroy(:force)

        expect(User.count).to eq(0)
      end
    end

    context 'user.bio.destroy' do
      it 'to be true' do
        user = User.create!
        Bio.create!(user_id: user.id)
        user.bio.destroy

        expect(user.bio.archived?).to eq(true)
      end

      it 'to be 0' do
        user = User.create!
        Bio.create!(user_id: user.id)
        user.bio.destroy(:force)

        expect(Bio.count).to eq(0)
      end
    end

    context 'license.destroy' do
      it 'to be 0' do
        license = License.create!
        license.destroy

        expect(License.count).to eq(0)
      end
    end

    context 'user.license.destroy' do
      it 'to be 0' do
        user = User.create!
        License.create!(user_id: user.id)
        user.license.destroy

        expect(License.count).to eq(0)
      end
    end

    context 'user.license.destroy(:force)' do
      it 'to be 0' do
        user = User.create!
        License.create!(user_id: user.id)
        user.license.destroy(:force)

        expect(License.count).to eq(0)
      end
    end

    context 'user.comments.last.destroy' do
      it 'to be 2' do
        user = User.create!
        2.times { Comment.create!(user_id: user.id) }
        user.comments.last.destroy

        expect(Comment.count).to eq(2)
      end

      it 'to be true' do
        user = User.create!
        2.times { Comment.create!(user_id: user.id) }
        user.comments.last.destroy

        expect(Comment.first.unarchived?).to eq(true)
        expect(Comment.last.archived?).to eq(true)
      end
    end

    context 'user.cars.first.destroy' do
      it 'to be 1' do
        user = User.create!
        user.cars.create!
        user.cars.first.destroy

        expect(Car.count).to eq(1)
      end

      it 'to be 0' do
        user = User.create!
        car = user.cars.create!
        Insurance.create!(car_id: car.id)
        user.cars.first.destroy

        expect(Insurance.count).to eq(0)
      end

      it 'to be 2' do
        user = User.create!
        car = user.cars.create!
        2.times { car.drivers.create! }
        user.cars.first.destroy

        expect(Driver.count).to eq(2)
      end

      it 'to be 0' do
        user = User.create!
        car = user.cars.create!
        2.times { car.drivers.create! }
        user.cars.first.destroy(:force)

        expect(Driver.count).to eq(0)
      end
    end

    context 'user.cars.first.destroy' do
      it 'to be 0' do
        user = User.create!
        car = user.cars.create!
        Insurance.create!(car_id: car.id)
        user.cars.first.destroy(:force)

        expect(Car.count).to eq(0)
        expect(Insurance.count).to eq(0)
      end
    end
  end

  describe '#destroy_all' do
    context 'user.destroy_all' do
      it 'to be 3' do
        3.times { User.create! }
        User.destroy_all

        expect(User.count).to eq(3)
      end

      it 'to be 2' do
        user = User.create!
        car = user.cars.create!
        2.times { car.drivers.create! }
        User.destroy_all

        expect(Driver.count).to eq(2)
      end
    end
  end

  describe '#delete_all' do
    context 'user.delete_all' do
      it 'to be 0' do
        3.times { User.create! }
        User.delete_all

        expect(User.count).to eq(0)
      end

      it 'to be 0' do
        user = User.create!
        car = user.cars.create!
        2.times { car.drivers.create! }
        User.delete_all

        expect(Driver.count).to eq(2)
      end
    end
  end

  describe '#to_archival' do
    context 'user.to_archival' do
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
  end

  describe '#unarchive' do
    context 'user.unarchive' do
      it 'to be 1' do
        user = User.create!
        user.archive
        user.unarchive

        expect(User.count).to eq(1)
      end

      it 'to be nil' do
        user = User.create!
        user.archive
        user.unarchive

        expect(user.archived_at).to eq(nil)
      end

      it 'to be 0' do
        user = User.create!
        user.archive(:force)

        expect { user.unarchive }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'user.bio.unarchive' do
      it 'to be true' do
        user = User.create!
        Bio.create!(user_id: user.id)
        user.bio.archive
        user.bio.unarchive

        expect(user.bio.unarchived?).to eq(true)
      end

      it 'to be 0' do
        user = User.create!
        Bio.create!(user_id: user.id)
        user.bio.archive(:force)

        expect { user.cars.first.unarchive }.to raise_error(NoMethodError)
      end
    end

    context 'license.unarchive' do
      it 'to be 0' do
        license = License.create!
        license.archive
        license.unarchive

        expect(License.count).to eq(0)
      end
    end

    context 'user.license.unarchive' do
      it 'to be 0' do
        user = User.create!
        License.create!(user_id: user.id)
        user.license.archive
        user.license.unarchive

        expect(License.count).to eq(0)
      end
    end

    context 'user.license.unarchive' do
      it 'to be 0' do
        user = User.create!
        License.create!(user_id: user.id)
        user.license.archive(:force)
        user.license.unarchive

        expect(License.count).to eq(0)
      end
    end

    context 'user.comments.last.archive' do
      it 'to be 2' do
        user = User.create!
        2.times { Comment.create!(user_id: user.id) }
        user.comments.last.archive

        expect(Comment.count).to eq(2)
      end

      it 'to be true' do
        user = User.create!
        2.times { Comment.create!(user_id: user.id) }
        user.comments.last.archive

        expect(Comment.first.unarchived?).to eq(true)
        expect(Comment.last.archived?).to eq(true)
      end
    end

    context 'user.cars.first.unarchive' do
      it 'to be 1' do
        user = User.create!
        car = user.cars.create!
        Insurance.create!(car_id: car.id)
        user.cars.first.archive
        user.cars.first.unarchive

        expect(Car.count).to eq(1)
      end

      it 'to be 0' do
        user = User.create!
        car = user.cars.create!
        Insurance.create!(car_id: car.id)
        user.cars.first.archive
        user.cars.first.unarchive

        expect(Insurance.count).to eq(0)
      end

      it 'to be 2' do
        user = User.create!
        car = user.cars.create!
        2.times { car.drivers.create! }
        user.cars.first.archive
        user.cars.first.unarchive

        expect(Driver.count).to eq(2)
      end

      it 'to be raise error' do
        user = User.create!
        user.cars.create!
        user.cars.first.archive(:force)

        expect { user.cars.first.unarchive }.to raise_error(NoMethodError)
      end
    end
  end

end
