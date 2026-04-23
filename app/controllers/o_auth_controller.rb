class OAuthController < ApplicationController
  before_action :authenticate_user!

  def authorize
    render json: { error: 'Unsupported provider' }, status: :unprocessable_entity
  end

  def callback
    render json: { error: 'Unsupported provider' }, status: :unprocessable_entity
  end
end
