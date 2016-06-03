require "spec_helper"

describe ActiveArchive::Configuration do

  after(:all) {
    ActiveArchive.configure do |config|
      config.all_records_archivable  = false
      config.dependent_record_window = 3.seconds
    end
  }

  describe "#configure" do
    it "to be '91 test'" do
      ActiveArchive.configure do |config|
        config.all_records_archivable  = "91 test"
      end

      expect(ActiveArchive.configuration.all_records_archivable).to eq("91 test")
    end

    it "to be '19 test'" do
      ActiveArchive.configure do |config|
        config.dependent_record_window  = "19 test"
      end

      expect(ActiveArchive.configuration.dependent_record_window).to eq("19 test")
    end
  end

end
