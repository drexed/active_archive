module ActiveRecord
  module ConnectionAdapters
    class TableDefinition

      def timestamps_with_archived_at(options)
        timestamps_without_archived_at(options)
        column(:archived_at, :datetime) if ActiveArchive.configuration.all_records_archivable
      end

      alias_method_chain(:timestamps, :archived_at)

    end
  end
end