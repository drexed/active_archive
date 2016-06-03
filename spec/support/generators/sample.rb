ActiveArchive.configure do |config|
  config.all_records_archivable = false
  config.dependent_record_window = 3.seconds
end
