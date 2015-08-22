module ActiveRecord
  module ConnectionAdapters
    class TableDefinition

      def timestamps_with_archived_at(options)
        if ActiveArchive.configuration.all_records_archivable
          timestamps_without_archived_at(options)
          column(:archived_at, :datetime)
        end
      end

      alias_method_chain(:timestamps, :archived_at)

    end
  end
end