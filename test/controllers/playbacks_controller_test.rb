require "test_helper"

class PlaybacksControllerTest < ActionDispatch::IntegrationTest
  test "index groups playbacks by month" do
    user = users(:one)
    post login_url, params: {email: user.email, password: "password123"}
    assert_response :success

    playback_one = playbacks(:one)
    playback_two = playbacks(:two)

    get playbacks_url

    assert_response :success
    body = JSON.parse(response.body)

    january_key = Date.new(playback_one.created_at.year, playback_one.created_at.month).to_s
    march_key = Date.new(playback_two.created_at.year, playback_two.created_at.month).to_s

    assert_includes body["groups"].keys, january_key
    assert_includes body["groups"].keys, march_key

    january_counts = body["groups"][january_key]
    march_counts = body["groups"][march_key]

    assert_equal 1, january_counts.to_h[playback_one.release_id]
    assert_equal 1, march_counts.to_h[playback_two.release_id]

    releases = body["releases"]
    assert_equal releases(:one).artist, releases[playback_one.release_id.to_s]["artist"]
    assert_equal releases(:two).artist, releases[playback_two.release_id.to_s]["artist"]

    counts = body["counts"].to_h
    assert_equal 1, counts[playback_one.release_id]
    assert_equal 1, counts[playback_two.release_id]

    returned_ids = body["playbacks"].map { |p| p["id"] }
    assert_includes returned_ids, playback_one.id
    assert_includes returned_ids, playback_two.id
  end
end
