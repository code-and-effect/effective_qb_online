# One Quickbooks Realm / Company

module Effective
  class QbRealm < ActiveRecord::Base

    effective_resource do
      realm_id                    :string

      deposit_to_account_id       :string
      payment_method_id           :string

      access_token                :text
      access_token_expires_at     :datetime

      refresh_token               :text
      refresh_token_expires_at    :datetime

      timestamps
    end

    validates :realm_id, presence: true
    validates :realm_id, uniqueness: true, if: -> { new_record? }

    validates :access_token, presence: true
    validates :access_token_expires_at, presence: true

    validates :refresh_token, presence: true
    validates :refresh_token_expires_at, presence: true

    def to_s
      'Quickbooks Online Settings'
    end

    def company_id
      realm_id
    end

  end
end
