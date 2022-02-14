# One Quickbooks Realm / Company

module Effective
  class QbRealm < ActiveRecord::Base

    effective_resource do
      realm_id                    :string

      access_token                :text
      access_token_expires_at     :datetime

      refresh_token               :text
      refresh_token_expires_at    :datetime

      timestamps
    end

    validates :realm_id, presence: true, uniqueness: true

    validates :access_token, presence: true
    validates :access_token_expires_at, presence: true

    validates :refresh_token, presence: true

    def to_s
      realm_id.presence || 'New Quickbooks Realm'
    end

  end
end
