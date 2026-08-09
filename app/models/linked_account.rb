class LinkedAccount < ApplicationRecord
  belongs_to :user

  validates :provider, presence: true

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  # a row exists as soon as we start the handshake, so "linked" means we
  # actually got through the exchange and have usable tokens. discogs is
  # oauth1, so it needs the token secret too; other providers don't have one.
  def connected?
    return false if access_token.blank?

    case provider
    when "discogs"
      access_token_secret.present?
    else
      true
    end
  end
end
