class GardenItem < ApplicationRecord
  belongs_to :item
  belongs_to :garden
end
