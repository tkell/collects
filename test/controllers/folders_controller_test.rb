require "test_helper"

class FoldersControllerTest < ActionDispatch::IntegrationTest
  def log_in(user)
    post login_url, params: {email: user.email, password: "password123"}
    assert_response :success
  end

  test "index returns the folders for the collection" do
    log_in(users(:one))

    get folders_url, params: {c: collections(:one).name}

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal ["Folder One", "Folder Two"], body.map { |f| f["name"] }.sort
  end

  test "index does not return folders from other collections" do
    log_in(users(:one))

    get folders_url, params: {c: collections(:one).name}

    names = JSON.parse(response.body).map { |f| f["name"] }
    assert_not_includes names, folders(:three).name
  end

  test "index returns not found for another user's collection" do
    log_in(users(:one))

    get folders_url, params: {c: collections(:two).name}

    assert_response :not_found
  end

  test "index requires authentication" do
    get folders_url, params: {c: collections(:one).name}

    assert_response :unauthorized
  end
end
