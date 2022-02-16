module Effective
  class QbReceiptItem < ActiveRecord::Base
    belongs_to :qb_receipt, class_name: 'Effective::QbInvoice'
    belongs_to :order_item, class_name: 'Effective::OrderItem'

    log_changes(to: :qb_receipt) if respond_to?(:log_changes)

    effective_resource do
      item_id       :string    # Optional when created

      timestamps
    end

    scope :deep, -> { includes(:qb_receipt, :order_item) }

    def to_s
      item_id.presence || 'New Qb Receipt Item'
    end

  end
end
