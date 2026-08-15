require 'test_helper'

class PasswordResetsControllerTest < ActionDispatch::IntegrationTest
  test "create returns static json if no user is found" do
    post password_resets_url, params: {email: "for-sure-not-a-real-email"}

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "If that email exists, a reset link has been sent", body["message"]
  end

  test "create returns static json, emails user, and creats token if user is found" do
    user = users(:one)
    post password_resets_url, params: {email: user.email}

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "If that email exists, a reset link has been sent", body["message"]
    assert_enqueued_emails 1 do
      UserMailer.password_reset_email(user).deliver_later
    end

    user.reload
    assert_not_nil user.password_reset_sent_at
    assert_not_nil user.password_reset_token
  end

  test "update fails if reset token is fake" do
    put password_resets_url, params: {token: "not a real token"}
    assert_response :not_found
  end

  test "update fails if reset token is expired" do
    user = users(:one)
    post password_resets_url, params: {email: user.email}
    assert_response :success

    user.reload
    user.update!(password_reset_sent_at: Time.current - 3.hours)
    token = user.password_reset_token

    patch password_update_url(token)
    assert_response :unprocessable_entity
  end

  # test "update changes password and clears reset token" do
  #   user = users(:one)
  #   post password_resets_url, params: {email: user.email}
  #   assert_response :success

  #   user.reload
  #   assert_not_nil user.password_reset_token
  #   token = user.password_reset_token
  #   new_password = "a-new-password"

  #   post password_resets_url, params: {token: token, password: new_password, password_confirmation: new_password}
  #   assert_response :success
  #   body = JSON.parse(response.body)
  #   assert_equal "Password updated successfully", body["message"]

  #   user.reload
  #   assert_not_nil user.password_reset_token
  # end
end
