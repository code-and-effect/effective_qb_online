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
      deposit_to_account_id       :string
      payment_method_id           :string

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

    def configured?
      realm_id.present? && access_token.present? && deposit_to_account_id.present? && payment_method_id.present?
    end

  end
end
