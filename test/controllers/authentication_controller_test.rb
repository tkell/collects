require "test_helper"

class AuthenticationControllerTest < ActionDispatch::IntegrationTest
  test "login succeeds with valid credentials" do
    user = users(:one)

    post login_url, params: {email: user.email, password: "password123"}

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "Logged in", body["message"]
    assert_equal user.id, body["user_id"]
  end

  test "logout clears session and cookie" do
    user = users(:one)
    post login_url, params: {email: user.email, password: "password123"}
    delete logout_url

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "Logged out", body["message"]
    assert_nil session[:user_id]
    assert_equal cookies[:jwt], ""
  end
end
