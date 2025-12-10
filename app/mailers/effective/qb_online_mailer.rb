module Effective
  class QbOnlineMailer < EffectiveQbOnline.parent_mailer_class
    include EffectiveMailer

    def sync_error(resource, opts = {})
      raise('expected an Effective::QbReceipt') unless resource.kind_of?(Effective::QbReceipt)

      @qb_receipt = resource
      @order = resource.order

      to = EffectiveOrders.qb_online_sync_error_recipients.presence || EffectiveOrders.mailer_admin
      cc = EffectiveQbOnline.sync_error_cc_recipients.presence

      subject = subject_for(__method__, "Quickbooks Sync Error - Order ##{@order.to_param}", resource, opts)
      headers = headers_for(resource, opts)

      mail(to: to, cc: cc, subject: subject, **headers)
    end

  end
end
