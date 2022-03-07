module Admin
  class QbOnlineController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)
    before_action { EffectiveResources.authorize!(self, :admin, :effective_qb_online) }

    include Effective::CrudController

    # /admin/quickbooks
    def index
      @page_title = 'QuickBooks Online'
    end

  end
end
