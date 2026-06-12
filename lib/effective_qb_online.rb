require 'quickbooks-ruby'
require 'faraday/net_http_persistent'
require 'effective_resources'
require 'effective_datatables'
require 'effective_qb_online/engine'
require 'effective_qb_online/version'

module EffectiveQbOnline
  def self.config_keys
    [
      :qb_realms_table_name, :qb_receipts_table_name, :qb_receipt_items_table_name,
      :mailer, :parent_mailer, :deliver_method, :mailer_layout, :mailer_sender, :mailer_admin, :mailer_subject,
      :oauth_client_id, :oauth_client_secret,
      :layout, :sync_error_cc_recipients
    ]
  end

  include EffectiveGem

  def self.mailer_class
    mailer&.constantize || Effective::QbOnlineMailer
  end

  def self.oauth2_client
    @oauth2_client ||= OAuth2::Client.new(
      oauth_client_id,
      oauth_client_secret,
      site: 'https://appcenter.intuit.com/connect/oauth2',
      authorize_url: 'https://appcenter.intuit.com/connect/oauth2',
      token_url: 'https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer',
      connection_opts: {
        request: { open_timeout: 10, timeout: 30 }
      }
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

  # Syncs the QuickBooks Online item names down into Effective::ItemName
  def self.sync_item_names!
    client = api()
    raise 'expected a connected QuickBooks Online realm' if client.blank?

    qb_item_names = client.item_names
    raise 'QuickBooks Online returned no items' if qb_item_names.blank?

    qb_item_names.each do |name|
      item_name = Effective::ItemName.where(name: name).first_or_initialize

      if item_name.new_record?
        item_name.save!
      elsif item_name.archived?
        item_name.unarchive!
      end
    end

    Effective::ItemName.unarchived.where.not(name: qb_item_names).find_each do |item_name|
      item_name.archive!
    end

    true
  end
end
