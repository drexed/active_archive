# frozen_string_literal: true

require 'spec_helper'

describe ActiveArchive::Configuration do
  after(:all) do
    ActiveArchive.configure do |config|
      config.all_records_archivable = false
    end
  end

  describe '.configure' do
    it 'to be "91 test" for all_records_archivable' do
      ActiveArchive.configuration.all_records_archivable = '91 test'

      expect(ActiveArchive.configuration.all_records_archivable).to eq('91 test')
    end
  end

end
