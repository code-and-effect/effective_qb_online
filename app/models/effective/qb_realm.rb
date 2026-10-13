# One QuickBooks Realm / Company

module Effective
  class QbRealm < ActiveRecord::Base

    effective_resource do
      # As per QuickBooks oAuth
      realm_id                    :string

      access_token                :text
      access_token_expires_at     :datetime

      refresh_token               :text
      refresh_token_expires_at    :datetime

      # Set on /admin/quickbooks
      deposit_to_account_id               :string
      payment_method_id                   :string
      order_number_as_transaction_number  :boolean, default: false

      reconnection_required_at            :datetime
      reconnection_reason                 :string

      timestamps
    end

    validates :realm_id, presence: true
    validates :realm_id, uniqueness: true, if: -> { new_record? }

    validates :access_token, presence: true
    validates :access_token_expires_at, presence: true

    validates :refresh_token, presence: true
    validates :refresh_token_expires_at, presence: true

    def to_s
      'QuickBooks Online Settings'
    end

    def reconnection_required?
      reconnection_required_at.present?
    end

    # Only the first failure for the current grant sends a notification. A failed
    # request using old credentials must not disable a newly reconnected grant.
    def require_reconnection!(reason:, refresh_token:)
      changed = false

      with_lock do
        if !reconnection_required? && self.refresh_token == refresh_token
          update!(reconnection_required_at: Time.current, reconnection_reason: reason)
          changed = true
        end
      end

      EffectiveQbOnline.send_email(:reconnection_required, self) if changed
      changed
    end

    def configured?
      realm_id.present? && access_token.present? && deposit_to_account_id.present? && payment_method_id.present?
    end

  end
end
