module Admin
  class QbOnlineController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)
    before_action { EffectiveResources.authorize!(self, :admin, :effective_qb_online) }

    include Effective::CrudController

    page_title 'QuickBooks Online'

    # /admin/quickbooks
    def index
    end

    # /admin/quickbooks/items
    def items
    end

  end
end
