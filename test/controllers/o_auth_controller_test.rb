require "test_helper"

class OAuthControllerTest < ActionDispatch::IntegrationTest
  test "should get authorize" do
    get o_auth_authorize_url
    assert_response :success
  end

  test "should get callback" do
    get o_auth_callback_url
    assert_response :success
  end
end
