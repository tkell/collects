class Garden < ApplicationRecord
  belongs_to :collection
  has_many :garden_items
  has_many :items, through: :garden_items

  accepts_nested_attributes_for :garden_items, allow_destroy: true, reject_if: :all_blank
end
