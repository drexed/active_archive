# frozen_string_literal: true

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

    def unarchive(opts = nil)
      with_transaction_returning_status do
        records = should_unarchive_parent_first?(opts) ? unarchival.reverse : unarchival
        records.each { |rec| rec.call(opts) }

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
        if archived? || new_record?
          save
        else
          set_archived_at(Time.now, force)
          each_counter_cache do |assoc_class, counter_cache_column, assoc_id|
            assoc_class.decrement_counter(counter_cache_column, assoc_id)
          end
        end
        return(true)
      end

      archived? ? self : false
    end

    def each_counter_cache
      _reflections.each do |name, reflection|
        next unless respond_to?(name.to_sym)

        association = send(name.to_sym)

        next if association.nil?
        next unless reflection.belongs_to? && reflection.counter_cache_column

        associated_class = association.class

        yield(associated_class, reflection.counter_cache_column, send(reflection.foreign_key))
      end
    end

    def retrieve_archived_record
      self.class.unscoped.find(id)
    end

    # rubocop:disable Metrics/AbcSize
    def retrieve_dependent_records
      dependent_records = {}

      self.class.reflections.each do |key, ref|
        next unless ref.options[:dependent] == :destroy

        records = send(key)
        next unless records
        records.respond_to?(:empty?) ? (next if records.empty?) : (records = [] << records)

        dependent_record = records.first
        dependent_record.nil? ? next : dependent_records[dependent_record.class] = records.map(&:id)
      end

      dependent_records
    end
    # rubocop:enable Metrics/AbcSize

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
        ->(validate) { unarchive_destroyed_dependent_records(validate) },
        lambda do |validate|
          run_callbacks(:unarchive) do
            set_archived_at(nil, validate)
            each_counter_cache do |assoc_class, counter_cache_column, assoc_id|
              assoc_class.increment_counter(counter_cache_column, assoc_id)
            end
            return(true)
          end
        end
      ]
    end

    # rubocop:disable Metrics/LineLength
    def dependent_records_for_unarchival(name, reflection)
      record = send(name)

      case reflection.macro.to_s.gsub('has_', '').to_sym
      when :many
        records = archived_at ? set_record_window(record, name, reflection) : record.unscope(where: :archived_at)
      when :one, :belongs_to
        self.class.unscoped { records = [] << record }
      end

      [records].flatten.compact
    end
    # rubocop:enable Metrics/LineLength

    def unarchive_destroyed_dependent_records(force = nil)
      self.class.reflections
          .select { |_, ref| ref.options[:dependent].to_s == 'destroy' && ref.klass.archivable? }
          .each do |name, ref|
            dependent_records_for_unarchival(name, ref).each { |rec| rec.try(:unarchive, force) }
            reload
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
      qtn = reflection.table_name
      window = ActiveArchive.configuration.dependent_record_window

      query = "#{qtn}.archived_at > ? AND #{qtn}.archived_at < ?"

      send(name).unscope(where: :archived_at)
                .where([query, archived_at - window, archived_at + window])
    end

    def should_force_destroy?(force)
      force.is_a?(Hash) ? force[:force] : (force == :force)
    end

    def should_ignore_validations?(force)
      force.is_a?(Hash) && (force[:validate] == false)
    end

    def should_unarchive_parent_first?(order)
      order.is_a?(Hash) && (order[:reverse] == true)
    end

  end
end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Base.send :include, ActiveArchive::Base
end
