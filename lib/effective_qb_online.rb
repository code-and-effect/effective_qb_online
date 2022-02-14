require 'quickbooks-ruby'
require 'effective_resources'
require 'effective_datatables'
require 'effective_qb_online/engine'
require 'effective_qb_online/version'

module EffectiveQbOnline

  def self.config_keys
    [
      :oauth_client_id, :oauth_client_secret,
      :layout
    ]
  end

  include EffectiveGem

  def self.oauth2_client
    client_id = oauth_client_id
    secret = oauth_client_secret

    params = {
      site: "https://appcenter.intuit.com/connect/oauth2",
      authorize_url: "https://appcenter.intuit.com/connect/oauth2",
      token_url: "https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer"
    }

    OAuth2::Client.new(client_id, secret, params)
  end

end
