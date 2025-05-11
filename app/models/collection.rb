class Collection < ApplicationRecord
  belongs_to :user
  has_many :gardens
  has_many :releases
  has_many :release_sources
  has_one :linked_account # optional

  validates :user, presence: true
end
