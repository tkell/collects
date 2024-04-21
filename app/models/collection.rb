class Collection < ApplicationRecord
  has_many :gardens
  has_many :releases
  belongs_to :user

  validates :user, presence: true
end
