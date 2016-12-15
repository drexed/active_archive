module ActiveArchive
  module TableDefinition

    def timestamps(*args)
      options = args.extract_options!

      column(:created_at, :datetime, options)
      column(:updated_at, :datetime, options)

      return unless ActiveArchive::Settings.config.all_records_archivable == true
      return if options[:skip]

      options[:null] = true
      column(:archived_at, :datetime, options)
    end

  end
end

ActiveRecord::ConnectionAdapters::TableDefinition.prepend(ActiveArchive::TableDefinition)
