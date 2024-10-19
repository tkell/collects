class Release < ApplicationRecord
  belongs_to :collection
  has_many :garden_releases
  has_many :tracks
  has_many :variants

  def as_json(options={})
    super(:include => [:tracks, :variants])
  end

  def current_variant
    variants.find(current_variant_id)
  end
end
