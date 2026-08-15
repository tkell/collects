class OAuthController < ApplicationController
  before_action :authenticate_user!

  def authorize
    provider = params[:provider]
    if provider != "discogs"
      render json: { error: 'Unsupported provider' }, status: :unprocessable_content
      return
    end
    # should this moved to the linked account model, probably
    # send POST to discogs with my id and secret, persist tokens + get discogs url,
    # return discogs url to front end, with my callback on it

    linked_account = LinkedAccount.find_or_create_by(user_id: @current_user.id, provider: "discogs")
    config = OAuthConfig.get_provider_config(provider)
    if provider == "discogs"
      consumer = OAuth::Consumer.new(
        config[:consumer_key],
        config[:consumer_secret],
        site: "https://api.discogs.com",
        signature_method: "PLAINTEXT"
      )
      body = {}
      request_token = consumer.get_request_token({"oauth_callback" => config[:callback_url]}, body, {"User-Agent" => config[:user_agent]})
      linked_account.request_token = request_token.token
      linked_account.request_token_secret = request_token.secret
      linked_account.save!

      discogs_auth_url = "https://discogs.com/oauth/authorize?oauth_token=#{request_token.token}"
      redirect_to discogs_auth_url, allow_other_host: true
      return
    end
  end

  def callback
    # still need to guard this a bit, but we'll think about it
    provider = params["provider"]
    verifier = params[:verifier]
    linked_account = LinkedAccount.find_by(user_id: @current_user.id, provider: provider)
    config = OAuthConfig.get_provider_config(provider)
    consumer = OAuth::Consumer.new(
      config[:consumer_key],
      config[:consumer_secret],
      site: "https://api.discogs.com",
      signature_method: "PLAINTEXT"
    )
    request_token = OAuth::RequestToken.new(
      consumer,
      linked_account.request_token,
      linked_account.request_token_secret
    )

    body = {}
    access_token = request_token.get_access_token(
      {oauth_verifier: verifier},
      body,
      {"User-Agent" => config[:user_agent]}
    )

    linked_account.access_token = access_token.token
    linked_account.access_token_secret = access_token.secret
    linked_account.request_token = "exchanged"
    linked_account.request_token_secret = "exchanged"
    linked_account.save!

    # capture verifier, send POST to discogs to get access tokens, save to my DB, delete the request token and request token secret
    render json: {"success": "success"} ## or something, maybe another redirect, or poll on the Settings page
  end
end
