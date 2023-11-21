class Collection < ApplicationRecord
  has_many :gardens
  has_many :items
end
