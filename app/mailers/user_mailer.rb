class UserMailer < ApplicationMailer
  def verification_email(user)
    @user = user
    @verification_url = "#{Rails.application.config.app_host}/verify_email?token=#{user.email_verification_token}"
    mail(to: user.email, subject: "Verify your email address")
  end
end
