class Variant < ApplicationRecord
  belongs_to :release

  serialize :colors, coder: JSON, type: Array
end
