class Garden < ApplicationRecord
  belongs_to :collection
  has_many :garden_items
end
