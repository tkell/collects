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
end
