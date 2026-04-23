require "test_helper"

class OAuthControllerTest < ActionDispatch::IntegrationTest
  test "authorize returns unsupported provider" do
    get oauth_authorize_url(provider: 'unknown'), headers: authenticated_headers
    assert_response :unprocessable_entity
  end

  test "callback returns unsupported provider" do
    get oauth_callback_url(provider: 'unknown'), headers: authenticated_headers
    assert_response :unprocessable_entity
  end
end
