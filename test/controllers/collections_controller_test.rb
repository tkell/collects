require "test_helper"

class CollectionsControllerTest < ActionDispatch::IntegrationTest
  test "index returns the current user's collections" do
    user = users(:one)
    post login_url, params: {email: user.email, password: "password123"}
    assert_response :success

    get collections_url

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body.length
    assert_equal collections(:one).name, body.first["name"]
  end
end
