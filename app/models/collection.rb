class Collection < ApplicationRecord
  belongs_to :user
  has_many :gardens, dependent: :destroy
  has_many :releases, dependent: :destroy
  has_many :release_sources, dependent: :destroy

  validates :user, presence: true

  RELEASE_SOURCE_TYPE_MAP = {
    'RubyHashReleaseSource' => 'json_file',
    'SpotifyExportifyCsvReleaseSource' => 'spotify_exportify_csv',
    'DiscogsOAuthReleaseSource' => 'discogs_oauth'
  }.freeze

  SORT_KEYS = {
    "a" => :artist,
    "t" => :title,
    "l" => :label,
    "y" => :release_year,
    "p" => 'purchase_date DESC'
  }

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


  def query_releases(offset, limit, query_string, release_year, purchase_date, sort, folder, randomize)
    data = releases
    if folder
      data = data.where(folder: p[:folder])
    end

    # format is `1990 - 1999`, or `1990`
    # could clean this up, what does 1990..1990 do?
    if release_year
      if release_year.include? "-"
        year_range = release_year.split("-")
        start_year = year_range[0].strip.to_i
        end_year = year_range[1].strip.to_i
        data = data.where(release_year: start_year..end_year)
      else
        data = data.where(release_year: Integer(release_year))
      end
    end

    if purchase_date
      if purchase_date.include? "-"
        year_range = purchase_date.split("-")
        start_year = year_range[0].strip.to_i
        end_year = year_range[1].strip.to_i
        start_date = "#{start_year}-01-01".to_date
        end_date = "#{end_year}-12-31".to_date
        data = data.where(purchase_date: start_date..end_date)
      else
        year = purchase_date.strip.to_i
        start_date = "#{year}-01-01".to_date
        end_date = "#{year}-12-31".to_date
        data = data.where(purchase_date: start_date..end_date)
      end
    end

    if query_string
      filter_string = "%" + Release.sanitize_sql_like(query_string) + "%"
      data = data
        .where("artist ILIKE :search_string OR title ILIKE :search_string OR label ILIKE :search_string", {search_string: filter_string})
    end

    # We use the front-end's "random" sort and pick an offset here, if we're randomizing
    if randomize
      sort = randomize
      real_offset = (rand() * data.size).floor # SQL call to get the size of the data!
    else
      real_offset = offset
    end

    # see above, options are artist, title, label, release_year, purchase_date
    if sort && sort.length > 0 && sort.size < 5
      sort_args = []
      sort.split("").each do |key|
        if SORT_KEYS.has_key?(key)
          sort_args << SORT_KEYS[key]
        end
      end
      data = data.order(*sort_args)
    end

    return data
      .limit(limit)
      .offset(real_offset)
      .includes(:tracks)
      .joins("LEFT JOIN variants ON variants.release_id = releases.id AND variants.id = releases.current_variant_id")
      .includes(:variants)
  end
end
