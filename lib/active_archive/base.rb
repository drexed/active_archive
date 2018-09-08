# frozen_string_literal: true

module ActiveArchive
  module Base

    def self.included(base)
      base.extend Methods
      base.extend Scopes

      base.instance_eval { define_model_callbacks(:unarchive) }
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

    def unarchive(opts = nil)
      with_transaction_returning_status do
        records = should_unarchive_parent_first?(opts) ? unarchival.reverse : unarchival
        records.each { |rec| rec.call(opts) }

        self
      end
    end

    alias_method :undestroy, :unarchive

    def destroy(force = nil)
      with_transaction_returning_status do
        if unarchivable? || should_force_destroy?(force)
          permanently_delete_records_after { super() }
        else
          destroy_with_active_archive(force)
        end
      end
    end

    alias_method :archive, :destroy

    def to_archival
      I18n.t("active_archive.archival.#{archived? ? :archived : :unarchived}")
    end

    private

    def unarchival
      [
        lambda do |validate|
          unarchive_destroyed_dependent_records(validate)
        end,
        lambda do |validate|
          run_callbacks(:unarchive) do
            set_archived_at(nil, validate)

            each_counter_cache do |assoc_class, counter_cache_column, assoc_id|
              assoc_class.increment_counter(counter_cache_column, assoc_id)
            end

            true
          end
        end
      ]
    end

    def get_archived_record
      self.class.unscoped.find(id)
    end

    def set_archived_at(value, force = nil)
      return self unless archivable?
      record = get_archived_record
      record.archived_at = value

      begin
        should_ignore_validations?(force) ? record.save(validate: false) : record.save!

        if ::ActiveRecord::VERSION::MAJOR >= 5 && ::ActiveRecord::VERSION::MINOR >= 2
          # TODO
        elsif ::ActiveRecord::VERSION::MAJOR >= 5
          @changed_attributes = record.send(:saved_changes)
          @previous_mutation_tracker = record.send(:previous_mutation_tracker)
          @mutation_tracker = nil
        elsif ::ActiveRecord::VERSION::MAJOR >= 4
          @previously_changed = record.instance_variable_get('@previously_changed')
        end

        @attributes = record.instance_variable_get('@attributes')
      rescue => error
        record.destroy
        raise error
      end
    end

    def each_counter_cache
      _reflections.each do |name, reflection|
        next unless respond_to?(name.to_sym)

        association = send(name.to_sym)

        next if association.nil?
        next unless reflection.belongs_to? && reflection.counter_cache_column

        yield(association.class, reflection.counter_cache_column, send(reflection.foreign_key))
      end
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

        true
      end

      archived? ? self : false
    end

    def add_record_window(_request, name, reflection)
      qtn = reflection.table_name
      window = ActiveArchive.configuration.dependent_record_window
      query = "#{qtn}.archived_at > ? AND #{qtn}.archived_at < ?"

      send(name).unscope(where: :archived_at)
                .where(query, archived_at - window, archived_at + window)
    end

    def unarchive_destroyed_dependent_records(force = nil)
      destroyed_dependent_relations.each do |relation|
        relation.to_a.each do |destroyed_dependent_record|
          destroyed_dependent_record.try(:unarchive, force)
        end
      end

      reload
    end

    # rubocop:disable Metrics/AbcSize
    def destroyed_dependent_relations
      dependent_permanent_reflections(self.class).map do |name, relation|
        case relation.macro.to_s.gsub('has_', '').to_sym
        when :many
          if archived_at
            add_record_window(send(name), name, relation)
          else
            send(name).unscope(where: :archived_at)
          end
        when :one, :belongs_to
          self.class.unscoped { Array(send(name)) }
        end
      end
    end
    # rubocop:enable Metrics/AbcSize

    def attempt_notifying_observers(callback)
      notify_observers(callback)
    rescue NoMethodError
      # do nothing
    end

    def dependent_record_ids
      dependent_reflections(self.class).reduce({}) do |records, (key, _)|
        found = Array(send(key)).compact
        next records if found.empty?
        records.update(found.first.class => found.map(&:id))
      end
    end

    def permanently_delete_records_after(&block)
      dependent_records = dependent_record_ids
      result = yield(block)
      permanently_delete_records(dependent_records) if result
      result
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

    def dependent_reflections(klass)
      klass.reflections.select do |_, reflection|
        reflection.options[:dependent] == :destroy
      end
    end

    def dependent_permanent_reflections(klass)
      dependent_reflections(klass).select do |_name, reflection|
        reflection.klass.archivable?
      end
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
