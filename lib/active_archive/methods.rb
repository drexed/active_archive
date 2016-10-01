module ActiveArchive
  module Methods

    def archivable?
      columns.detect { |col| col.name == 'archived_at' }
    end

    def archive_all(conditions = nil)
      conditions ? where(conditions).destroy_all : destroy_all
    end

    def unarchive_all(conditions = nil)
      (conditions ? where(conditions) : all).to_a.each(&:unarchive)
    end

  end
end
