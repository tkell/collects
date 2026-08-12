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

  test "show filters releases by release_year" do
    user = users(:one)
    post login_url, params: {email: user.email, password: "password123"}
    assert_response :success

    get collection_url(collections(:one).name), params: {release_year: "1999"}

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body.length
    assert_equal releases(:one).title, body.first["title"]
  end

  test "show filters releases by purchase_date" do
    user = users(:one)
    post login_url, params: {email: user.email, password: "password123"}
    assert_response :success

    get collection_url(collections(:one).name), params: {purchase_date: "2015"}

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body.length
    assert_equal releases(:three).title, body.first["title"]
  end

  test "show filters releases by purchase_date range" do
    user = users(:one)
    post login_url, params: {email: user.email, password: "password123"}
    assert_response :success

    get collection_url(collections(:one).name), params: {purchase_date: "2014-2016"}

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body.length
    assert_equal releases(:three).title, body.first["title"]
  end

  test "show filters releases by artist" do
    user = users(:one)
    post login_url, params: {email: user.email, password: "password123"}
    assert_response :success

    get collection_url(collections(:one).name), params: {filter: "Siamese"}

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body.length
    assert_equal releases(:one).title, body.first["title"]
  end

  test "show filters releases by title" do
    user = users(:one)
    post login_url, params: {email: user.email, password: "password123"}
    assert_response :success

    get collection_url(collections(:one).name), params: {filter: "Bengal"}

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body.length
    assert_equal releases(:two).title, body.first["title"]
  end

  test "show filters releases by label" do
    user = users(:one)
    post login_url, params: {email: user.email, password: "password123"}
    assert_response :success

    get collection_url(collections(:one).name), params: {filter: "Burmese"}

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body.length
    assert_equal releases(:three).title, body.first["title"]
  end
end
