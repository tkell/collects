class Item < ApplicationRecord
  belongs_to :collection
  has_many :garden_items
  has_many :subitems
end
