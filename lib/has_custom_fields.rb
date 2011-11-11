require 'custom_fields/custom_field_base'
include ::CustomFields

module ActiveRecord # :nodoc:
  module Has # :nodoc:
    ##
    # HasCustomFields allow for the Entity-attribute-value model (EAV), also 
    # known as object-attribute-value model and open schema on any of your ActiveRecord
    # models. 
    #
    module CustomFields

      ALLOWABLE_TYPES = ['select', 'checkbox', 'text', 'date']

      Object.const_set('TagFacade', Class.new(Object)).class_eval do
        def initialize(object_with_custom_fields, scope, scope_id)
          @object = object_with_custom_fields
          @scope = scope
          @scope_id = scope_id
        end
        def [](tag)
          # puts "** Calling get_custom_field_attribute for #{@object.class},#{tag},#{@scope},#{@scope_id}"
          return @object.get_custom_field_attribute(tag, @scope, @scope_id)
        end
      end

      Object.const_set('ScopeIdFacade', Class.new(Object)).class_eval do
        def initialize(object_with_custom_fields, scope)
          @object = object_with_custom_fields
          @scope = scope
        end
        def [](scope_id)
          # puts "** Returning a TagFacade for #{@object.class},#{@scope},#{scope_id}"
          return TagFacade.new(@object, @scope, scope_id)
        end
      end

      Object.const_set('ScopeFacade', Class.new(Object)).class_eval do
        def initialize(object_with_custom_fields)
          @object = object_with_custom_fields
        end
        def [](scope)
          # puts "** Returning a ScopeIdFacade for #{@object.class},#{scope}"
          return ScopeIdFacade.new(@object, scope)
        end
      end

      def self.included(base) # :nodoc:
        base.extend ClassMethods
      end

      module ClassMethods

        ##
        # Will make the current class have eav behaviour.
        #
        # The following options are available on for has_custom_fields to modify
        # the behavior. Reasonable defaults are provided:
        #
        # * <tt>value_class_name</tt>:
        #   The class for the related model. This defaults to the
        #   model name prepended to "Attribute". So for a "User" model the class
        #   name would be "UserAttribute". The class can actually exist (in that
        #   case the model file will be loaded through Rails dependency system) or
        #   if it does not exist a basic model will be dynamically defined for you.
        #   This allows you to implement custom methods on the related class by
        #   simply defining the class manually.
        # * <tt>table_name</tt>:
        #   The table for the related model. This defaults to the
        #   attribute model's table name.
        # * <tt>relationship_name</tt>:
        #   This is the name of the actual has_many
        #   relationship. Most of the type this relationship will only be used
        #   indirectly but it is there if the user wants more raw access. This
        #   defaults to the class name underscored then pluralized finally turned
        #   into a symbol.
        # * <tt>foreign_key</tt>:
        #   The key in the attribute table to relate back to the
        #   model. This defaults to the model name underscored prepended to "_id"
        # * <tt>name_field</tt>:
        #   The field which stores the name of the attribute in the related object
        # * <tt>value_field</tt>:
        #   The field that stores the value in the related object
        def has_custom_fields(options = {})

          # Provide default options
          options[:fields_class_name] ||= self.name + 'Field'
          options[:fields_table_name] ||= options[:fields_class_name].tableize
          options[:fields_relationship_name] ||= options[:fields_class_name].underscore.to_sym

          options[:values_class_name] ||= self.name + 'Attribute'
          options[:values_table_name] ||= options[:values_class_name].tableize
          options[:relationship_name] ||= options[:values_class_name].tableize.to_sym

          options[:foreign_key] ||= self.name.foreign_key
          options[:base_foreign_key] ||= self.name.underscore.foreign_key
          options[:name_field] ||= 'name'
          options[:value_field] ||= 'value'
          options[:parent] = self.name

          ::Rails.logger.debug("OPTIONS: #{options.inspect}")
          puts("OPTIONS: #{options.inspect}")

          # Init option storage if necessary
          cattr_accessor :custom_field_options
          self.custom_field_options ||= Hash.new

          # Return if already processed.
          return if self.custom_field_options.keys.include? options[:values_class_name]

          # Attempt to load related class. If not create it
          begin
            Object.const_get(options[:values_class_name])
          rescue
            Object.const_set(options[:fields_class_name],
              Class.new(::CustomFields::CustomFieldBase)).class_eval do
                set_table_name options[:fields_table_name]
                def self.reloadable? #:nodoc:
                  false
                end
              end
            ::CustomFields.const_set(options[:fields_class_name], Object.const_get(options[:fields_class_name]))

            Object.const_set(options[:values_class_name],
            Class.new(ActiveRecord::Base)).class_eval do
              cattr_accessor :custom_field_options
              belongs_to options[:fields_relationship_name],
                :class_name => '::CustomFields::' + options[:fields_class_name].singularize
              alias_method :field, options[:fields_relationship_name]
              
              def self.reloadable? #:nodoc:
                false
              end
              
              def validate
                field = self.field
                raise "Couldn't load field" if !field

                if field.style == "select" && !self.value.blank?
                  # raise self.field.select_options.find{|f| f == self.value}.to_s
                  if field.select_options.find{|f| f == self.value}.nil?
                    raise "Invalid option: #{self.value}.  Should be one of #{field.select_options.join(", ")}"
                    self.errors.add_to_base("Invalid option: #{self.value}.  Should be one of #{field.select_options.join(", ")}")
                    return false
                  end
                end
              end
            end
            ::CustomFields.const_set(options[:values_class_name], Object.const_get(options[:values_class_name]))
          end

          # Store options
          self.custom_field_options[self.name] = options

          # Only mix instance methods once
          unless self.included_modules.include?(ActiveRecord::Has::CustomFields::InstanceMethods)
            send :include, ActiveRecord::Has::CustomFields::InstanceMethods
          end

          # Modify attribute class
          attribute_class = Object.const_get(options[:values_class_name])
          base_class = self.name.underscore.to_sym

          attribute_class.class_eval do
            belongs_to base_class, :foreign_key => options[:base_foreign_key]
            alias_method :base, base_class # For generic access
          end

          # Modify main class
          class_eval do
            has_many options[:relationship_name],
              :class_name => options[:values_class_name],
              :table_name => options[:values_table_name],
              :foreign_key => options[:foreign_key],
              :dependent => :destroy

            # The following is only setup once
            unless method_defined? :read_attribute_without_custom_field_behavior

              # Carry out delayed actions before save
              after_validation :save_modified_custom_field_attributes, :on => :update

              private

              alias_method_chain :read_attribute, :custom_field_behavior
              alias_method_chain :write_attribute, :custom_field_behavior
            end
          end
          
          create_attribute_table
          
        end

        def custom_field_fields(scope, scope_id)
          options = custom_field_options[self.name]
          klass = Object.const_get(options[:fields_class_name])
          return klass.send("find_all_by_#{scope}_id", scope_id, :order => :id)
        end
        
      end

      module InstanceMethods

        def self.included(base) # :nodoc:
          base.extend ClassMethods
        end

        module ClassMethods

          ##
          # Rake migration task to create the versioned table using options passed to has_custom_fields
          #
          def create_attribute_table(options = {})
            options = custom_field_options[self.name]
            klass = Object.const_get(options[:fields_class_name])
            return if connection.tables.include?(options[:values_table_name])

            # todo: get the real pkey type and name
            scope_fkeys = options[:scopes].collect{|s| "#{s.to_s}_id"}
            
            ActiveRecord::Base.transaction do
            
              self.connection.create_table(options[:fields_table_name], options) do |t|
                t.string options[:name_field], :null => false, :limit => 63
                t.string :style, :null => false, :limit => 15
                t.string :select_options
                scope_fkeys.each do |s|
                  t.integer s
                end
                t.timestamps
              end
              self.connection.add_index options[:fields_table_name], scope_fkeys + [options[:name_field]], :unique => true, 
                :name => "#{options[:fields_table_name]}_unique_index"
            
              # add foreign keys for scoping tables
              options[:scopes].each do |s|
                self.connection.execute <<-FOO
                  alter table #{options[:fields_table_name]}
                    add foreign key (#{s.to_s}_id)
                    references
                    #{eval(s.to_s.classify).table_name}(#{eval(s.to_s.classify).primary_key})
                FOO
              end
              
              # add xor constraint
              if !options[:scopes].empty? 
                self.connection.execute <<-FOO
                  alter table #{options[:fields_table_name]} add constraint scopes_xor check
                    (1 = #{options[:scopes].collect{|s| "(#{s.to_s}_id is not null)::integer"}.join(" + ")})
                FOO
              end
              
              self.connection.create_table(options[:values_table_name], options) do |t|
                t.integer options[:foreign_key], :null => false
                t.integer options[:fields_table_name].singularize.foreign_key, :null => false
                t.string options[:value_field], :null => false
                t.timestamps
              end
              
              self.connection.add_index options[:values_table_name], options[:foreign_key]
              self.connection.add_index options[:values_table_name], options[:fields_table_name].singularize.foreign_key
              
              self.connection.execute <<-FOO
                alter table #{options[:values_table_name]} 
                add foreign key (#{options[:fields_table_name].singularize.foreign_key})
                references #{options[:fields_table_name]}(#{eval(options[:fields_class_name]).primary_key})
              FOO
            end
          end

          ##
          # Rake migration task to drop the attribute table
          #
          def drop_attribute_table(options = {})
            options = custom_field_options[self.name]
            self.connection.drop_table options[:values_table_name]
          end

          def drop_field_table(options = {})
            options = custom_field_options[self.name]
            self.connection.drop_table options[:fields_table_name]
          end

        end

        def get_custom_field_attribute(attribute_name, scope, scope_id)
          read_attribute_with_custom_field_behavior(attribute_name, scope, scope_id)
        end

        def set_custom_field_attribute(attribute_name, value, scope, scope_id)
          write_attribute_with_custom_field_behavior(attribute_name, value, scope, scope_id)
        end

        def custom_fields=(custom_fields_data)
          custom_fields_data.each do |scope, scoped_ids|
            scoped_ids.each do |scope_id, attrs|
              attrs.each do |k, v|
                self.set_custom_field_attribute(k, v, scope, scope_id)
              end
            end
          end
        end

        def custom_fields
          return ScopeFacade.new(self)
        end

        private

        ##
        # Called after validation on update so that eav attributes behave
        # like normal attributes in the fact that the database is not touched
        # until save is called.
        #
        def save_modified_custom_field_attributes
          return if @save_attrs.nil?
          @save_attrs.each do |s|
            if s.value.nil? || (s.respond_to?(:empty) && s.value.empty?)
              s.destroy if !s.new_record?
            else
              s.save
            end
          end
          @save_attrs = []
        end

        def get_value_object(attribute_name, scope, scope_id)
          ::Rails.logger.debug("scope/id is: #{scope}/#{scope_id}")
          options = custom_field_options[self.class.name]
          model_fkey = options[:foreign_key].singularize
          fields_class = options[:fields_class_name]
          values_class = options[:values_class_name]
          value_field = options[:value_field]
          fields_fkey = options[:fields_table_name].singularize.foreign_key
          fields = Object.const_get(fields_class)
          values = Object.const_get(values_class)
          ::Rails.logger.debug("fkey is: #{fields_fkey}")
          ::Rails.logger.debug("fields class: #{fields.to_s}")
          ::Rails.logger.debug("values class: #{values.to_s}")
          f = fields.send("find_by_name_and_#{scope}_id", attribute_name, scope_id)
          raise "No field #{attribute_name} for #{scope} #{scope_id}" if f.nil?
          ::Rails.logger.debug("field: #{f.inspect}")
          field_id = f.id
          model_id = self.id
          value_object = values.send("find_by_#{model_fkey}_and_#{fields_fkey}", model_id, field_id)

          if value_object.nil?
            value_object = values.new model_fkey => self.id,
              fields_fkey => f.id
          end
          return value_object
        end

        ##
        # Overrides ActiveRecord::Base#read_attribute
        #
        def read_attribute_with_custom_field_behavior(attribute_name, scope = nil, scope_id = nil)
          return read_attribute_without_custom_field_behavior(attribute_name) if scope.nil?
          value_object = get_value_object(attribute_name, scope, scope_id)
          case value_object.field.style
          when "date"
            ::Rails.logger.debug("reading date object: #{value_object.value}")
            return Date.parse(value_object.value) if value_object.value
          end
          return value_object.value
        end

       ##
        # Overrides ActiveRecord::Base#write_attribute
        #
        def write_attribute_with_custom_field_behavior(attribute_name, value, scope = nil, scope_id = nil)
          return write_attribute_without_custom_field_behavior(attribute_name, value) if scope.nil?

          ::Rails.logger.debug("attribute_name(#{attribute_name}) value(#{value.inspect}) scope(#{scope}) scope_id(#{scope_id})")
          value_object = get_value_object(attribute_name, scope, scope_id)
          case value_object.field.style
          when "date"
            ::Rails.logger.debug("date object: #{value["date(1i)"].to_i}, #{value["date(2i)"].to_i}, #{value["date(3i)"].to_i}")
            begin
              new_date = !value["date(1i)"].empty? && !value["date(2i)"].empty? && !value["date(3i)"].empty? ?
                Date.civil(value["date(1i)"].to_i, value["date(2i)"].to_i, value["date(3i)"].to_i) :
                nil
            rescue ArgumentError
              new_date = nil
            end
            value_object.send("value=", new_date) if value_object
          else
            value_object.send("value=", value) if value_object
          end
          @save_attrs ||= []
          @save_attrs << value_object
        end

      end

    end
  end
end

ActiveRecord::Base.send :include, ActiveRecord::Has::CustomFields
