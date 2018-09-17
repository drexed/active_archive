# frozen_string_literal: true

module ActiveArchive
  module Methods

    def archivable?
      columns.detect { |col| col.name == 'archived_at' }
    end

    def archive_all(conditions = nil)
      (conditions ? where(conditions) : all).each(&:archive)
    end

    def unarchive_all(conditions = nil)
      (conditions ? where(conditions) : all).each(&:unarchive)
    end

  end
end
