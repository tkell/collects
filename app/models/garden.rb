class Garden < ApplicationRecord
  belongs_to :collection
  has_many :garden_items
  has_many :items, through: :garden_items
end
