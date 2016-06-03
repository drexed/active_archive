module ActiveArchive
  module Base

    def self.included(base)
      base.extend Methods
      base.extend Scopes

      base.instance_eval { define_model_callbacks(:unarchive) }
    end

    def archived?
      archivable? ? !!archived_at : destroyed?
    end

    def archivable?
      respond_to?(:archived_at)
    end

    def destroy(force=nil)
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

    def unarchive(options=nil)
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
      notify_observers(callback)
    rescue NoMethodError
      # RETURN
    end

    def destroy_with_active_archive(force=nil)
      run_callbacks(:destroy) do
        (archived? || new_record?) ? save : set_archived_at(Time.now, force)
        true
      end

      archived? ? self : false
    end

    def get_archived_record
      self.class.unscoped.find(id)
    end

    def get_dependent_records
      dependent_records = {}

      self.class.reflections.each do |key, reflection|
        next unless reflection.options[:dependent] == :destroy
        next unless records = send(key)

        if records.respond_to? :size
          next unless records.size > 0
        else
          records = [] << records
        end

        dependent_record = records.first
        next if dependent_record.nil?
        dependent_records[dependent_record.class] = records.map(&:id)
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
      dependent_records = get_dependent_records
      dependent_results = yield
      permanently_delete_records(dependent_records) if dependent_results
      return(dependent_results)
    end

    def unarchival
      [
        ->(validate) { unarchive_destroyed_dependent_records(validate) },
        ->(validate) do
          run_callbacks(:unarchive) do
            set_archived_at(nil, validate)
            return(true)
          end
        end
      ]
    end

    def unarchive_destroyed_dependent_records(force = nil)
      self.class.reflections.select do |name, reflection|
        "destroy" == reflection.options[:dependent].to_s && reflection.klass.archivable?
      end.each do |name, reflection|
        cardinality = reflection.macro.to_s.gsub("has_", "").to_sym
        case cardinality
        when :many
          records = (archived_at ? set_record_window(send(name), name, reflection) : send(name))
        when :one, :belongs_to
          self.class.unscoped { records = [] << send(name) }
        end

        [records].flatten.compact.each { |d| d.unarchive(force) }
        send(name, :reload)
      end
    end

    def set_archived_at(value, force=nil)
      return self unless archivable?
      record = get_archived_record
      record.archived_at = value

      begin
        should_ignore_validations?(force) ? record.save(validate: false) : record.save!
        @attributes = record.instance_variable_get("@attributes")
      rescue => e
        record.destroy
        raise(e)
      end
    end

    def set_record_window(request, name, reflection)
      send(name).unscope(where: :archived_at)
                .where([
                        "#{reflection.quoted_table_name}.archived_at > ? AND #{reflection.quoted_table_name}.archived_at < ?",
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
