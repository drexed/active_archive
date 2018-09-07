# frozen_string_literal: true

module ActiveArchive
  module Methods

    def archivable?
      columns.detect { |col| col.name == 'archived_at' }
    end

    def archive_all(conditions = nil)
      (conditions ? where(conditions) : all).to_a.each(&:archive)
    end

    def archive_all!(conditions = nil)
      (conditions ? where(conditions) : all).to_a.each { |r| r.send(:archive, :force) }
    end

    alias_method :destroy_all!, :archive_all!

    def unarchive_all(conditions = nil)
      (conditions ? where(conditions) : all).to_a.each(&:unarchive)
    end

    alias_method :undestroy_all, :unarchive_all

  end
end
