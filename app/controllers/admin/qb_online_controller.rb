module Admin
  class QbOnlineController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)
    before_action { EffectiveResources.authorize!(self, :admin, :effective_qb_online) }

    include Effective::CrudController

    page_title 'Quickbooks Online'

    # /admin/quickbooks
    def index
      @api = EffectiveQbOnline.api

      authorize! :index, Effective::QbRealm

      render(@api.present? ? 'index' : 'instructions')
    end

  end
end
