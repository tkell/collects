class LinkedAccount < ApplicationRecord
  belongs_to :user

  validates :provider, presence: true

  def expired?
    expires_at.present? && expires_at < Time.current
  end
end
