class Person < ActiveRecord::Base
  
  has_custom_field_behavior :class_name => 'Preference', 
                   :name_field => :key
                   
  has_custom_field_behavior :class_name => 'PersonContactInfo', 
                   :foreign_key => :contact_id, 
                   :fields => %w(phone aim icq)

  def custom_field_attributes(model)
    model == Preference ? %w(project_search project_order) : nil
  end
end