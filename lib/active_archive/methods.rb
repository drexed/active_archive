module ActiveArchive
  module Methods

    def archivable?
      columns.lazy.detect { |c| c.name == 'archived_at'.freeze }
    end

    def archive_all(conditions=nil)
      conditions ? where(conditions).destroy_all : destroy_all
    end

    def unarchive_all(conditions=nil)
      (conditions ? where(conditions) : all).to_a.lazy.each { |r| r.unarchive }
    end

  end
end