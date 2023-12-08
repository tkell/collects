class Item < ApplicationRecord
  belongs_to :collection
  has_many :garden_items
  has_many :subitems

  serialize :colors, coder: JSON, type: Array

  def as_json(options={})
    super(include: :subitems)
  end
end
