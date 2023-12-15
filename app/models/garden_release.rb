class GardenRelease < ApplicationRecord
  belongs_to :release
  belongs_to :garden
end
