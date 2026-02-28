Rails.application.config.mailgun = {
  domain: ENV['MAILGUN_DOMAIN'],
  smtp_login: ENV['MAILGUN_SMTP_LOGIN'],
  smtp_password: ENV['MAILGUN_SMTP_PASSWORD']
}

module MailgunConfig
  def self.configured?
    Rails.application.config.mailgun[:domain].present? &&
    Rails.application.config.mailgun[:smtp_login].present?
  end
end

