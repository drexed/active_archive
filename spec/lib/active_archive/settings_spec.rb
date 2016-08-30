require 'spec_helper'

describe ActiveArchive::Settings do

  after(:all) do
    ActiveArchive::Settings.configure do |config|
      config.all_records_archivable = false
      config.dependent_record_window = 3.seconds
    end
  end

  describe '#configure' do
    it 'to be "91 test"' do
      ActiveArchive::Settings.configure do |config|
        config.all_records_archivable = '91 test'
      end

      expect(ActiveArchive::Settings.config.all_records_archivable).to eq('91 test')
    end

    it 'to be "19 test"' do
      ActiveArchive::Settings.configure do |config|
        config.dependent_record_window = '19 test'
      end

      expect(ActiveArchive::Settings.config.dependent_record_window).to eq('19 test')
    end
  end

end
