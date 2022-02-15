module Effective
  class QbInvoiceItem < ActiveRecord::Base
    belongs_to :qb_invoice, class_name: 'Effective::QbInvoice'
    belongs_to :order_item, class_name: 'Effective::OrderItem'

    log_changes(to: :qb_invoice) if respond_to?(:log_changes)

    effective_resource do
      item_id       :string

      timestamps
    end

    scope :deep, -> { includes(:qb_invoice, :order_item) }

    def to_s
      item_id.presence || 'New Qb Invoice Item'
    end

  end
end
