module Effective
  class QbReceiptTool

    def create_qb_receipt!(order:)
      raise('expected an Effective::Order') unless order.kind_of?(Effective::Order)

      qb_receipt = Effective::QbReceipt.where(order: order).first_or_initialize

      order.order_items.each do |order_item|
        qb_receipt_item = qb_receipt.qb_receipt_item(order_item: order_item)

        item_id = order_item.purchasable.try(:qb_item_id)
        item_name = order_item.purchasable.try(:qb_item_name)

        if item_id.blank? && item_name.present?
          item_id = api.item(name: item_name)&.id
        end

        qb_receipt_item.assign_attributes(item_id: item_id)
      end

      qb_receipt.save!
      qb_receipt
    end

    def sync_qb_receipt!(receipt:)
      raise('expected a persisted Effective::QbReceipt') unless receipt.kind_of?(Effective::QbReceipt) && receipt.persisted?
    end

    private

    def api
      @api ||= EffectiveQbOnline.api
    end

  end
end
