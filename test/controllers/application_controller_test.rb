require "test_helper"

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  test "allows a request with a valid session" do
    user = users(:one)
    post login_url, params: {email: user.email, password: "password123"}
    assert_response :success

    get collections_url

    assert_response :success
  end

  test "rejects a request with no session at all" do
    get collections_url

    assert_response :unauthorized
    assert_equal "Unauthorized", JSON.parse(response.body)["error"]
  end

  test "rejects a request after logging out" do
    user = users(:one)
    post login_url, params: {email: user.email, password: "password123"}
    assert_response :success

    delete logout_url
    assert_response :success

    get collections_url

    assert_response :unauthorized
  end

  test "rejects a request with a tampered jwt cookie" do
    user = users(:one)
    post login_url, params: {email: user.email, password: "password123"}
    assert_response :success

    cookies[:jwt] = "not-a-valid-encrypted-cookie"

    get collections_url

    assert_response :unauthorized
  end

  test "rejects a request whose user no longer exists" do
    user = User.create!(email: "disappearing@example.com", username: "disappearing", password: "password123", email_verified_at: Time.current)
    post login_url, params: {email: user.email, password: "password123"}
    assert_response :success

    user.destroy

    get collections_url

    assert_response :unauthorized
  end
end
