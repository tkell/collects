class Collection < ApplicationRecord
  belongs_to :user
  has_many :gardens, dependent: :destroy
  has_many :releases, dependent: :destroy
  has_many :release_sources, dependent: :destroy

  validates :user, presence: true

  RELEASE_SOURCE_TYPE_MAP = {
    'RubyHashReleaseSource' => 'json_file',
    'SpotifyExportifyCsvReleaseSource' => 'spotify_exportify_csv'
  }.freeze

  def release_source_type
    RELEASE_SOURCE_TYPE_MAP[release_sources.first&.type]
  end

  def as_json(options = {})
    super(options).merge('release_source_type' => release_source_type)
  end

  def update_release_sources(overwrite_strategy)
    current_releases = releases.joins(:variants).pluck(:external_id, :colors).index_by {|r| r[0]}
    total_added = 0
    release_sources.each do | rs |
      added = rs.import_releases(overwrite_strategy, current_releases)
      total_added += added
    end

    self.level += total_added
    save!
  end
end
