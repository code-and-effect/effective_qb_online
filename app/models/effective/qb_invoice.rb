module Effective
  class QbInvoice < ActiveRecord::Base
    belongs_to :order, class_name: 'Effective::Order'

    log_changes if respond_to?(:log_changes)

    has_many :qb_invoice_items, inverse_of: :qb_invoice, dependent: :delete_all
    accepts_nested_attributes_for :qb_invoice_items

    acts_as_statused(:ready, :completed, :errored)

    effective_resource do
      result            :text

      # Acts as Statused
      status            :string
      status_steps      :text

      timestamps
    end

    scope :deep, -> { includes(:order, :qb_invoice_items) }

    def to_s
      order.to_s
    end

    # Find or build
    def qb_invoice_item(order_item:)
      qb_invoice_items.find { |item| item.order_item == order_item } ||
      qb_invoice_items.build(order_item: order_item)
    end

  end
end
