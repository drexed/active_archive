module ActiveArchive
  module Base

    def self.included(base)
      base.extend Methods
      base.extend Scopes

      base.instance_eval do
        define_model_callbacks :unarchive

        before_unarchive :unarchive_destroyed_dependent_records
      end
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
          destroy_with_permanent_records(force)
        end
      end
    end

    alias_method(:archive, :destroy)
    alias_method(:archive!, :destroy)

    def to_archival
      I18n.t("active_archive.archival.#{archived? ? :archived : :unarchived}")
    end

    def unarchive(validate=nil)
      with_transaction_returning_status do
        run_callbacks(:unarchive) { set_archived_at(nil, validate) }
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
      begin
        notify_observers(callback)
      rescue NoMethodError => e
        # RETURN
      end
    end

    def destroy_with_permanent_records(force=nil)
      run_callbacks(:destroy) { archived? || (new_record? ? save : set_archived_at(Time.now, force)) }
      archived? ? self : false
    end

    def get_dependent_records
      dependent_records = {}
      self.class.reflections.lazy.each do |key, reflection|
        if reflection.options[:dependent] == :destroy
          next unless records = self.send(key)
          if records.respond_to?(:size)
            next unless records.size > 0
          else
            records = [] << records
          end
          dependent_record = records.first
          next if dependent_record.nil?
          dependent_records[dependent_record.class] = records.map(&:id)
        end
      end
      return(dependent_records)
    end

    def permanently_delete_records(dependent_records)
      dependent_records.lazy.each do |klass, ids|
        ids.each do |id|
          record = begin
            klass.unscoped.find(id)
          rescue ::ActiveRecord::RecordNotFound
            next
          end
          record.archived_at = nil
          record.destroy(:force)
        end
      end
    end

    def permanently_delete_records_after(&block)
      dependent_records = get_dependent_records
      dependent_results = block.call
      permanently_delete_records(dependent_records) if dependent_results
      return(dependent_results)
    end

    def unarchive_destroyed_dependent_records
      self.class.reflections
                .lazy
                .select { |name, reflection| (reflection.options[:dependent].to_s == 'destroy'.freeze) && reflection.klass.archivable? }
                .each do |name, reflection|
                  cardinality = reflection.macro.to_s.gsub('has_'.freeze, ''.freeze)

                  if cardinality == 'many'.freeze
                    records = archived_at.nil? ? send(name).unscoped : send(name).unscoped.where(
                        [
                          "#{reflection.quoted_table_name}.archived_at > ? AND #{reflection.quoted_table_name}.archived_at < ?",
                          archived_at - ActiveArchive.configuration.dependent_record_window,
                          archived_at + ActiveArchive.configuration.dependent_record_window
                        ]
                      )
                  elsif cardinality == 'one'.freeze or cardinality == 'belongs_to'.freeze
                    self.class.unscoped do
                      records = [] << send(name)
                    end
                  end

                  [records].flatten.compact.lazy.each { |d| d.unarchive }
                  send(name, :reload)
                end
    end

    def set_archived_at(value, force=nil)
      return self unless archivable?
      record = self.class.unscoped.find(id)
      record.archived_at = value

      begin
        should_ignore_validations?(force) ? record.save(validate: false) : record.save!

        if ::Gem::Version.new(::ActiveRecord::VERSION::STRING) < ::Gem::Version.new('4.2.0'.freeze)
          @attributes       = record.attributes
          @attributes_cache = record.attributes.except(record.class.serialized_attributes.keys)

          if defined?(::ActiveRecord::AttributeMethods::Serialization::Attribute)
            serialized_attribute_class = ::ActiveRecord::AttributeMethods::Serialization::Attribute
            self.class.serialized_attributes.lazy.each do |key, coder|
              @attributes[key] = serialized_attribute_class.new(coder, @attributes[key], :unserialized) if @attributes.key?(key)
            end
          end
        else
          @attributes = record.instance_variable_get('@attributes'.freeze)
        end
      rescue Exception => e
        record.destroy
        raise(e)
      end
    end

    def should_force_destroy?(force)
      (Hash === force) ? force[:force] : (:force == force)
    end

    def should_ignore_validations?(force)
      (Hash === force) && (false == force[:validate])
    end

  end
end