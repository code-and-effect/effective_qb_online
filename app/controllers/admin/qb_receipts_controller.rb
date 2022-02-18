module Admin
  class QbReceiptsController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)
    before_action { EffectiveResources.authorize!(self, :admin, :effective_qb_online) }

    include Effective::CrudController

    submit :sync, 'Save and Sync', redirect: -> { effective_qb_online.admin_quickbooks_path }

  end
end
