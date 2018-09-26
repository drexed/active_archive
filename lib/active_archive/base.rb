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

    def archival?
      return destroyed? if unarchivable?

      (will_save_change_to_archived_at? || saved_change_to_archived_at?) && archived?
    end

    def archivable?
      respond_to?(:archived_at)
    end

    def archived?
      archivable? ? !archived_at.nil? : destroyed?
    end

    def archive
      return destroy if unarchivable?

      with_transaction_returning_status do
        run_callbacks :archive do
          mark_as_archived
          mark_relections_as_archived

          self
        end
      end
    end

    def unarchival?
      return !destroyed? if unarchivable?

      (will_save_change_to_archived_at? || saved_change_to_archived_at?) && unarchived?
    end

    def unarchived?
      !archived?
    end

    def unarchivable?
      !archivable?
    end

    def unarchive
      return self if unarchivable?

      with_transaction_returning_status do
        run_callbacks :unarchive do
          mark_as_unarchived
          mark_relections_as_unarchived

          self
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

    # rubocop:disable Metrics/CyclomaticComplexity
    def mark_relections_as_archived
      self.class.reflections.each do |table_name, reflection|
        next unless dependent_destroy?(reflection)

        dependents = reflection_dependents(table_name)
        next if dependents.nil?

        action = case [reflection_marco(reflection), archivable?]
                 when [:one, true] then :archive
                 when [:one, false] then :destroy
                 when [:many, true] then :archive_all
                 when [:many, false] then :destroy_all
                 end

        dependents.send(action)
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    def mark_relections_as_unarchived
      self.class.reflections.each do |table_name, reflection|
        next unless dependent_destroy?(reflection)

        klass = relection_klass(table_name)
        next unless klass.archivable?

        dependents = reflection_dependents(table_name)
        next if dependents.nil?

        action = case reflection_marco(reflection)
                 when :one then :unarchive
                 when :many then :unarchive_all
                 end

        dependents.send(action)
      end
    end

    def dependent_destroy?(reflection)
      reflection.options[:dependent] == :destroy
    end

    def reflection_dependents(table_name)
      send(table_name)
    end

    def relection_klass(table_name)
      table_name.classify.constantize
    end

    def reflection_marco(reflection)
      reflection.macro.to_s.gsub('has_', '').to_sym
    end

  end
end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Base.include(ActiveArchive::Base)
end
