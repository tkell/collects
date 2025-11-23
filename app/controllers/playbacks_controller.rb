class PlaybacksController < ApplicationController
  before_action :authenticate_user

  def index
    p = playbacks_read_params
    start_date = Date.parse(p[:start_date])
    end_date = Date.parse(p[:end_date])
    all_playbacks = Playback
      .joins(:release)
      .where("playbacks.created_at >= ?", start_date).where("playbacks.created_at <= ?", end_date)
      .includes(:release)
      .order(created_at: :desc)

    counts = Hash.new(0)
    releases = Hash.new()
    all_playbacks.each do |p|
      releases[p.release.id] = p.release
      counts[p.release.id] += 1
    end
    sorted_counts = counts.sort_by { |release_id, count| count }.reverse!

    render json: {playbacks: all_playbacks, counts: sorted_counts, releases: releases}, status: :ok
  end

  def new
    @playback = Playback.new
  end

  def create
    user_id = @current_user_id
    release_id = playbacks_params
    @playback = Playback.new(release_id: release_id, user_id: user_id)

    release = Release.find(release_id)
    release.points += 1
    release.save

    if @playback.save
      render json: @playback, status: :ok
    else
      render json: @playback.errors, status: :unprocessable_entity
    end
  end

  private
  def playbacks_params
    params.require(:release_id)
  end

  def playbacks_read_params
    today = Date.today + 1.day
    today_str = today.to_s
    epoch_str = "1970-1-1"
    params
      .permit(:start_date, :end_date, "playback")
      .with_defaults(start_date: epoch_str, end_date: today_str)
  end
end
