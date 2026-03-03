class UserMailer < ApplicationMailer
  def verification_email(user)
    @user = user
    @verification_url = "#{Rails.application.config.app_host}/api/verify_email?token=#{user.email_verification_token}"
    mail(to: user.email, subject: "Verify your email address")
  end

  def password_reset_email(user)
    @user = user
    @reset_url = "#{Rails.application.config.app_host}/login/?reset_token=#{user.password_reset_token}"
    mail(to: user.email, subject: "Reset your password")
  end
end
