module ActiveArchive
  module Base

    def self.included(base)
      base.extend Methods
      base.extend Scopes

      base.instance_eval { define_model_callbacks(:unarchive) }
    end

    def archived?
      archivable? ? !archived_at.nil? : destroyed?
    end

    def archivable?
      respond_to?(:archived_at)
    end

    def destroy(force = nil)
      with_transaction_returning_status do
        if unarchivable? || should_force_destroy?(force)
          permanently_delete_records_after { super() }
        else
          destroy_with_active_archive(force)
        end
      end
    end

    alias_method(:archive, :destroy)
    alias_method(:archive!, :destroy)

    def to_archival
      I18n.t("active_archive.archival.#{archived? ? :archived : :unarchived}")
    end

    def unarchive(options = nil)
      with_transaction_returning_status do
        (should_unarchive_parent_first?(options) ? unarchival.reverse : unarchival).each { |r| r.call(options) }
        self
      end
    end

    alias_method(:unarchive!, :unarchive)

    def unarchived?
      !archived?
    end

    def unarchivable?
      !archivable?
    end

    private

    def attempt_notifying_observers(callback)
      notify_observers(callback) if respond_to?(:notify_observers)
    end

    def destroy_with_active_archive(force = nil)
      run_callbacks(:destroy) do
        archived? || new_record? ? save : set_archived_at(Time.now, force)
        return(true)
      end

      archived? ? self : false
    end

    def retrieve_archived_record
      self.class.unscoped.find(id)
    end

    def retrieve_dependent_records
      dependent_records = {}

      self.class.reflections.each do |key, reflection|
        next unless reflection.options[:dependent] == :destroy

        records = send(key)
        next unless records
        records.respond_to?(:empty?) ? (next if records.empty?) : (records = [] << records)

        dependent_record = records.first
        dependent_record.nil? ? next : dependent_records[dependent_record.class] = records.map(&:id)
      end

      dependent_records
    end

    def permanently_delete_records(dependent_records)
      dependent_records.each do |klass, ids|
        ids.each do |id|
          record = klass.unscoped.where(klass.primary_key => id).first
          next unless record
          record.archived_at = nil
          record.destroy(:force)
        end
      end
    end

    def permanently_delete_records_after(&block)
      dependent_records = retrieve_dependent_records
      dependent_results = yield(block)
      permanently_delete_records(dependent_records) if dependent_results
      dependent_results
    end

    def unarchival
      [
        -> (validate) { unarchive_destroyed_dependent_records(validate) },
        lambda do |validate|
          run_callbacks(:unarchive) do
            set_archived_at(nil, validate)
            return(true)
          end
        end
      ]
    end

    def dependent_records_for_unarchival(name, reflection)
      case reflection.macro.to_s.gsub('has_', '').to_sym
      when :many
        records = archived_at ? set_record_window(send(name), name, reflection) : send(name)
      when :one, :belongs_to
        self.class.unscoped { records = [] << send(name) }
      end

      [records].flatten.compact
    end

    def unarchive_destroyed_dependent_records(force = nil)
      self.class.reflections
          .select { |_, reflection| 'destroy' == reflection.options[:dependent].to_s && reflection.klass.archivable? }
          .each do |name, reflection|
            dependent_records_for_unarchival(name, reflection).each { |record| record.unarchive(force) }
          end
    end

    def set_archived_at(value, force = nil)
      return self unless archivable?
      record = retrieve_archived_record
      record.archived_at = value

      begin
        should_ignore_validations?(force) ? record.save(validate: false) : record.save!
        @attributes = record.instance_variable_get('@attributes')
      rescue => error
        record.destroy
        raise(error)
      end
    end

    def set_record_window(_, name, reflection)
      quoted_table_name = reflection.quoted_table_name

      send(name).unscope(where: :archived_at)
                .where([
                         "#{quoted_table_name}.archived_at > ? AND #{quoted_table_name}.archived_at < ?",
                         archived_at - ActiveArchive.configuration.dependent_record_window,
                         archived_at + ActiveArchive.configuration.dependent_record_window
                       ])
    end

    def should_force_destroy?(force)
      force.is_a?(Hash) ? force[:force] : (:force == force)
    end

    def should_ignore_validations?(force)
      force.is_a?(Hash) && (false == force[:validate])
    end

    def should_unarchive_parent_first?(order)
      order.is_a?(Hash) && (true == order[:reverse])
    end

  end
end
