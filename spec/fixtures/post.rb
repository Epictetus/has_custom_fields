class Post < ActiveRecord::Base
  
  has_custom_field_behavior
  
  validates_presence_of :intro, :message => "can't be blank", :on => :create
end