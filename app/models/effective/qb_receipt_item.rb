module Effective
  class QbReceiptItem < ActiveRecord::Base
    belongs_to :qb_receipt
    belongs_to :order_item

    log_changes(to: :qb_receipt) if respond_to?(:log_changes)

    effective_resource do
      # Will be blank when first created. Populated by QbSalesReceipt.build_from_receipt!
      item_id       :string

      timestamps
    end

    scope :deep, -> { includes(:qb_receipt, :order_item) }

    def to_s
      item_id.presence || 'New Qb Receipt Item'
    end

    def order_item_qb_name
      item_id || order_item.purchasable.try(:qb_item_id) || order_item.purchasable.try(:qb_item_name)
    end

  end
end
