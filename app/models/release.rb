class Release < ApplicationRecord
  belongs_to :collection
  has_many :garden_releases
  has_many :tracks
  has_many :variants

  serialize :colors, coder: JSON, type: Array

  def as_json(options={})
    super(include: :tracks)
  end
end
