class User < ApplicationRecord
  has_many :collections
  has_many :gardens, through: :collections
  has_many :releases, through: :collections

  validates :email, presence: true, uniqueness: true
  validates :username, presence: true
end
