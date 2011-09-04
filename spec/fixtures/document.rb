class Document < ActiveRecord::Base
  has_custom_field_behavior

  def is_custom_field_attribute?(attr_name, model)
    attr_name =~ /attr$/
  end
end