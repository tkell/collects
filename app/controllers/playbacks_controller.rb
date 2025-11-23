class PlaybacksController < ApplicationController
  before_action :authenticate_user

  def index
    p = playbacks_read_params
    start_date = Date.parse(p[:start_date])
    end_date = Date.parse(p[:end_date])
    grouping = p[:g]
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


    groups = Hash.new()
    i = start_date
    while i < end_date do
        key = get_key(i, grouping)
        groups[key] = Hash.new(0)
        i = i + 1.send(grouping) # ruby magic!
    end

    all_playbacks.each do |p|
      group_key = get_key(p.created_at, grouping)
      groups[group_key][p.release_id] += 1
    end
    groups.keys.each do |k|
      groups[k] = groups[k].sort_by { |release_id, count| count }.reverse!
    end
    groups = groups.sort.reverse.to_h


    render json: {playbacks: all_playbacks, counts: sorted_counts, releases: releases, groups: groups}, status: :ok
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
    end_date = Date.today + 1.day
    end_date_str= end_date.to_s
    year = Date.today.year
    start_of_year_str = Date.new(year).to_s
    params
      .permit(:start_date, :end_date, :g, "playback")
      .with_defaults(start_date: start_of_year_str, end_date: end_date_str, g: "month")
  end

  def get_key(date, grouping)
    if grouping == "year"
      return Date.new(date.year)
    elsif grouping == "month"
      return Date.new(date.year, date.month)
    elsif grouping == "day"
      return Date.new(date.year, date.month, date.day)
    end
  end
end
