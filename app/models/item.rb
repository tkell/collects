class Item < ApplicationRecord
  belongs_to :collection
  has_and_belongs_to_many :gardens
end
