module Admin
  class QbRealmsController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)
    before_action { EffectiveResources.authorize!(self, :admin, :effective_qb_online) }

    include Effective::CrudController

    on :save, redirect: -> { effective_qb_online.admin_quickbooks_path }

  end
end
