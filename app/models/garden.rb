class Garden < ApplicationRecord
  belongs_to :collection
  has_many :garden_releases
  has_many :releases, through: :garden_releases

  accepts_nested_attributes_for :garden_releases, allow_destroy: true, reject_if: :all_blank
end
