require 'dry-configurable'

module ActiveArchive
  class Settings
    extend Dry::Configurable

    setting :all_records_archivable, false
    setting :dependent_record_window, 3.seconds

  end
end
