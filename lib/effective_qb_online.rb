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
    options = {
      site: "https://appcenter.intuit.com/connect/oauth2",
      authorize_url: "https://appcenter.intuit.com/connect/oauth2",
      token_url: "https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer"
    }

    OAuth2::Client.new(oauth_client_id, oauth_client_secret, options)
  end

  def self.api(realm: nil)
    realm ||= Effective::QbRealm.first
    return nil if realm.blank?

    Effective::QbApi.new(realm: realm)
  end

end
