class GardenItem < ApplicationRecord
  belongs_to :release
  belongs_to :garden
end
