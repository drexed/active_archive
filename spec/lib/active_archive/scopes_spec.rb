require "spec_helper"

describe ActiveArchive::Scopes do
  before {
    3.times { User.create! }
    6.times { User.create!.destroy }
  }

  context "#archived" do
    it "to be 6" do
      expect(User.archived.count).to eq(User.all.select(&:archived?).size)
    end

    it "to be archived" do
      User.archived.each { |m| expect(m).to be_archived }
    end
  end

  context "#unarchived" do
    it "to be 3" do
      expect(User.unarchived.count).to eq(User.all.reject(&:archived?).size)
    end

    it "to not be archived" do
      User.unarchived.each { |m| expect(m).not_to be_archived }
    end
  end
end
