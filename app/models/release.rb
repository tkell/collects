class Release < ApplicationRecord
  belongs_to :collection
  has_many :garden_items
  has_many :tracks

  serialize :colors, coder: JSON, type: Array

  def as_json(options={})
    super(include: :tracks)
  end
end
