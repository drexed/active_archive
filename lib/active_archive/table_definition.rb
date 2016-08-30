module ActiveArchive
  module TableDefinition

    def timestamps(*args)
      options = args.extract_options!
      options[:null] = false if options[:null].nil?

      column(:created_at, :datetime, options)
      column(:updated_at, :datetime, options)

      if ActiveArchive::Settings.config.all_records_archivable == true
        options[:null] = true
        column(:archived_at, :datetime, options)
      end
    end

  end
end

ActiveRecord::ConnectionAdapters::TableDefinition.prepend(ActiveArchive::TableDefinition)
