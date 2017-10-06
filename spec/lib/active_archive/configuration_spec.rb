# frozen_string_literal: true

require 'spec_helper'

describe ActiveArchive::Configuration do
  after(:all) do
    ActiveArchive.configure do |config|
      config.all_records_archivable = false
      config.dependent_record_window = 3.seconds
    end
  end

  describe '.configure' do
    it 'to be "91 test" for all_records_archivable' do
      ActiveArchive.configure.all_records_archivable = '91 test'

      expect(ActiveArchive.config.all_records_archivable).to eq('91 test')
    end

    it 'to be "19 test" dependent_record_window' do
      ActiveArchive.configure.dependent_record_window = '19 test'

      expect(ActiveArchive.config.dependent_record_window).to eq('19 test')
    end
  end

end
