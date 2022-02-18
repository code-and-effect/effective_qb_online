module Admin
  class QbReceiptsController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)
    before_action { EffectiveResources.authorize!(self, :admin, :effective_qb_online) }

    include Effective::CrudController

    on :skip, redirect: -> { effective_qb_online.admin_quickbooks_path }

    on :sync, redirect: -> {
      resource.completed? ? effective_qb_online.admin_quickbooks_path : :edit
    }

    submit :sync, 'Save and Sync'

  end
end
