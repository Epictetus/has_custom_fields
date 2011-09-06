module CustomFields
  class CustomFieldBase < ActiveRecord::Base

    serialize :select_options
    validates_presence_of :name,
      :message => 'Please specify the field name.'
    validates_presence_of :select_options_data,
      :if => "self.style.to_sym == :select",
      :message => "You must enter options for the selection, separated by commas."

    def self.inherited(chld)
      super(chld)
      chld.class_eval <<-FOO
        validates_uniqueness_of :name, :scope => [:user_id, :organization_id], :message => 'The field name is already taken.'
        validates_inclusion_of :style, :in => ALLOWABLE_TYPES, :message => "Invalid style.  Should be #{ALLOWABLE_TYPES.join(', ')}."
      FOO
    end

    def select_options_data
      (self.select_options || []).join(",")
    end

    def select_options_data=(data)
      self.select_options = data.split(",").collect{|f| f.strip}
    end

    scope :find_all_by_scope, lambda {|scope| {where("#{scope}_id = #{self.id}")}}
  end
end