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
    OAuth2::Client.new(
      oauth_client_id,
      oauth_client_secret,
      site: 'https://appcenter.intuit.com/connect/oauth2',
      authorize_url: 'https://appcenter.intuit.com/connect/oauth2',
      token_url: 'https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer'
    )
  end

  def self.api(realm: nil)
    realm ||= Effective::QbRealm.first
    return nil if realm.blank?

    Effective::QbApi.new(realm: realm)
  end

  def self.sync_order!(order, perform_now: false)
    raise 'expected a purchased Effective::Order' unless order.kind_of?(Effective::Order) && order.purchased?

    if perform_now
      qb_receipt = Effective::QbReceipt.create_from_order!(order)
      qb_receipt.sync!
    else
      QbSyncOrderJob.perform_later(order)
    end

    true
  end

  def self.skip_order!(order)
    raise 'expected a purchased Effective::Order' unless order.kind_of?(Effective::Order) && order.purchased?

    qb_receipt = Effective::QbReceipt.create_from_order!(order)
    qb_receipt.skip!
  end

end
