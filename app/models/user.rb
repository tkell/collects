class User < ApplicationRecord
  has_secure_password

  has_many :collections
  has_many :gardens, through: :collections
  has_many :releases, through: :collections
  has_many :playbacks
  has_many :linked_accounts
  has_many :annotations

  validates :email, presence: true, uniqueness: true
  validates :username, presence: true

  # Find a user's linked account for a specific provider
  def linked_account_for(provider)
    linked_accounts.find_by(provider: provider)
  end

  # Check if user has a linked account for a provider
  def linked_to?(provider)
    linked_accounts.exists?(provider: provider)
  end

  def verify_email!
    update!(email_verified_at: Time.current, email_verification_token: nil)
  end

  def email_verified?
    email_verified_at.present?
  end

  def generate_password_reset_token!
    update!(
      password_reset_token: SecureRandom.urlsafe_base64(32),
      password_reset_sent_at: Time.current
    )
  end

  def password_reset_expired?
    password_reset_sent_at.nil? || password_reset_sent_at < 2.hours.ago
  end

  def clear_password_reset_token!
    update!(password_reset_token: nil, password_reset_sent_at: nil)
  end
end
