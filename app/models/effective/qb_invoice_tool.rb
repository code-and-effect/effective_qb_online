module Effective
  class QbInvoiceTool

    def create_qb_invoice!(order:)
      raise('expected an Effective::Order') unless order.kind_of?(Effective::Order)

      qb_invoice = Effective::QbInvoice.where(order: order).first_or_initialize

      order.order_items.each do |order_item|
        qb_invoice_item = qb_invoice.qb_invoice_item(order_item: order_item)

        item_id = order_item.purchasable.try(:qb_item_id)
        item_name = order_item.purchasable.try(:qb_item_name)

        if item_id.blank? && item_name.present?
          item_id = api.item(name: item_name)&.id
        end

        qb_invoice_item.assign_attributes(item_id: item_id.presence || 'Unknown')
      end

      qb_invoice.save!
      qb_invoice
    end

    def sync_qb_invoice!(invoice:)
      raise('expected a persisted Effective::QbInvoice') unless invoice.kind_of?(Effective::QbInvoice) && invoice.persisted?

      

    end

    private

    def api
      @api ||= EffectiveQbOnline.api
    end

  end
end
