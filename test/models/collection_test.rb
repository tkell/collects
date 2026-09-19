require "test_helper"

class CollectionTest < ActiveSupport::TestCase
  def page_ids(collection, offset, limit, sort, folder = nil)
    collection
      .query_releases(offset, limit, nil, nil, nil, sort, folder, nil)
      .map { |r| r["id"] }
  end

  test "paging through a purchase_date sort never repeats a release" do
    collection = collections(:one)
    total = collection.releases.count

    all_ids = page_ids(collection, 0, total, "p")
    paged_ids = (0...total).step(2).flat_map { |offset| page_ids(collection, offset, 2, "p") }

    assert_equal total, all_ids.size
    assert_equal all_ids.uniq, all_ids
    assert_equal all_ids, paged_ids
  end

  test "paging with no sort never repeats a release" do
    collection = collections(:one)
    total = collection.releases.count

    paged_ids = (0...total).step(2).flat_map { |offset| page_ids(collection, offset, 2, nil) }

    assert_equal total, paged_ids.size
    assert_equal paged_ids.uniq, paged_ids
  end

  test "filtering by folder returns only that folder's releases" do
    collection = collections(:one)

    ids = page_ids(collection, 0, 100, nil, "Shorthair")

    assert_equal [releases(:batch_one).id, releases(:batch_two).id].sort, ids.sort
  end
end
