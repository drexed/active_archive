# frozen_string_literal: true

module ActiveArchive
  class Configuration

    attr_accessor :all_records_archivable, :dependent_record_window

    def initialize
      @all_records_archivable = false
      @dependent_record_window = 3.seconds
    end

  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configuration=(config)
    @configuration = config
  end

  def self.configure
    yield(configuration)
  end

end
