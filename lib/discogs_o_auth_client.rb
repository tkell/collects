require 'json'
require 'oauth'

# Thin wrapper around the bits of the discogs API we need to import a
# collection: who am I, what's in my collection, and what's on each record.
class DiscogsOAuthClient
  SITE = "https://api.discogs.com"
  PER_PAGE = 100

  # discogs allows 60 authenticated requests/minute, so we pace ourselves and
  # back off harder when the remaining-requests header gets low
  MIN_REQUEST_INTERVAL = 1.0
  LOW_REMAINING = 5
  LOW_REMAINING_PAUSE = 10

  class Error < StandardError; end

  def initialize(linked_account)
    if linked_account.nil? || linked_account.access_token.blank? || linked_account.access_token_secret.blank?
      raise Error, "No discogs account linked - please connect discogs first"
    end

    @config = OAuthConfig.get_provider_config('discogs')
    consumer = OAuth::Consumer.new(
      @config[:consumer_key],
      @config[:consumer_secret],
      site: SITE,
      signature_method: "PLAINTEXT"
    )
    @access_token = OAuth::AccessToken.new(
      consumer,
      linked_account.access_token,
      linked_account.access_token_secret
    )
    @last_request_at = nil
  end

  def username
    get_json("/oauth/identity")["username"]
  end

  # every release in the "All" folder (0), following pagination
  def collection_releases(username)
    releases = []
    page = 1

    loop do
      path = "/users/#{CGI.escape(username)}/collection/folders/0/releases" \
             "?per_page=#{PER_PAGE}&page=#{page}"
      data = get_json(path)
      releases.concat(data["releases"] || [])

      pages = data.dig("pagination", "pages").to_i
      break if page >= pages
      page += 1
    end

    releases
  end

  def release(release_id)
    get_json("/releases/#{release_id}")
  end

  private

  def get_json(path)
    throttle
    response = @access_token.get(path, { "User-Agent" => @config[:user_agent], "Accept" => "application/json" })
    note_rate_limit(response)

    unless response.is_a?(Net::HTTPSuccess)
      raise Error, "discogs API returned #{response.code} for #{path}"
    end

    JSON.parse(response.body)
  end

  def throttle
    return if @last_request_at.nil?

    elapsed = Time.now - @last_request_at
    sleep(MIN_REQUEST_INTERVAL - elapsed) if elapsed < MIN_REQUEST_INTERVAL
  end

  def note_rate_limit(response)
    @last_request_at = Time.now

    remaining = response["X-Discogs-Ratelimit-Remaining"]
    sleep(LOW_REMAINING_PAUSE) if remaining.present? && remaining.to_i <= LOW_REMAINING
  end
end
