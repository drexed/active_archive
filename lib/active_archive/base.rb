# frozen_string_literal: true

module ActiveArchive
  module Base

    def self.included(base)
      base.extend Methods
      base.extend Scopes

      base.instance_eval do
        define_model_callbacks :archive, only: %i[before after]
        define_model_callbacks :unarchive, only: %i[before after]
      end
    end

    def archivable?
      respond_to?(:archived_at)
    end

    def archived?
      archivable? ? !archived_at.nil? : destroyed?
    end

    def unarchived?
      !archived?
    end

    def unarchivable?
      !archivable?
    end

    def unarchive
      return if unarchivable?

      with_transaction_returning_status do
        run_callbacks :unarchive do
          mark_as_unarchived
          mark_relections_as_unarchived

          true
        end
      end
    end

    def archive
      return destroy if unarchivable?

      with_transaction_returning_status do
        run_callbacks :archive do
          mark_as_archived
          mark_relections_as_archived

          true
        end
      end
    end

    def to_archival
      I18n.t("active_archive.archival.#{archived? ? :archived : :unarchived}")
    end

    private

    def mark_as_archived
      self.archived_at = Time.now
      save(validate: false)
    end

    def mark_as_unarchived
      self.archived_at = nil
      save(validate: false)
    end

    def mark_relections_as_archived
      self.class.reflections.each do |table_name, reflection|
        next unless dependent_destroy?(reflection)

        klass = relection_klass(table_name)
        action = klass.archivable? ? :archive : :destroy
        klass.find_each(&action)
      end
    end

    def mark_relections_as_unarchived
      self.class.reflections.each do |table_name, reflection|
        next unless dependent_destroy?(reflection)

        klass = relection_klass(table_name)
        next unless klass.archivable?

        klass.find_each(&:unarchive)
      end
    end

    def dependent_destroy?(reflection)
      reflection.options[:dependent] == :destroy
    end

    def relection_klass(table_name)
      table_name.classify.constantize
    end

  end
end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Base.include(ActiveArchive::Base)
end
