require "test_helper"

class LinkedAccountsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get linked_accounts_index_url
    assert_response :success
  end

  test "should get show" do
    get linked_accounts_show_url
    assert_response :success
  end

  test "should get destroy" do
    get linked_accounts_destroy_url
    assert_response :success
  end
end
