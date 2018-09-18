# frozen_string_literal: true

module ActiveArchive
  module Methods

    def archivable?
      columns.detect { |col| col.name == 'archived_at' }
    end

    def archive_all(conditions = nil)
      records(conditions, action: :archive)
    end

    def unarchive_all(conditions = nil)
      records(conditions, action: :unarchive)
    end

    private

    def records(conditions = nil, action:)
      where(conditions).find_each(&action)
    end

  end
end
