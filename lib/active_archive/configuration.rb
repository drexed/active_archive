# frozen_string_literal: true

module ActiveArchive
  class Configuration

    attr_accessor :all_records_archivable

    def initialize
      @all_records_archivable = false
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
