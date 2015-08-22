class ActiveArchive::Configuration

  attr_accessor :all_records_archivable, :dependent_record_window

  def initialize
    @all_records_archivable  = false
    @dependent_record_window = 3.seconds
  end

end