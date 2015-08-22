require "spec_helper"

describe ActiveArchive::Methods do

  describe "#archivable?" do
    # TODO
  end

  describe "#archive_all" do
    it "to be 0" do
      3.times { Insurance.create! }
      Insurance.archive_all

      expect(Insurance.count).to eq(0)
    end

    it "to be 3" do
      3.times { User.create! }
      User.archive_all

      expect(User.count).to eq(3)
    end

    it "to be 2" do
      user = User.create!
      car  = user.cars.create!
      2.times { car.drivers.create! }
      User.archive_all

      expect(Driver.count).to eq(2)
    end
  end

  describe "#unarchive_all" do
    it "to be 0" do
      3.times { Insurance.create! }
      Insurance.archive_all
      Insurance.unarchive_all

      expect(Insurance.count).to eq(0)
    end

    it "to be 3" do
      3.times { User.create! }
      User.archive_all
      User.unarchive_all

      expect(User.count).to eq(3)
    end

    it "to be false" do
      user = User.create!
      car  = user.cars.create!
      2.times { car.drivers.create! }
      User.archive_all
      User.unarchive_all

      expect(Driver.first.archived?).to eq(false)
    end
  end

end