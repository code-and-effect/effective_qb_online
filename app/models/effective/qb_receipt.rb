module Effective
  class QbReceipt < ActiveRecord::Base
    belongs_to :order, class_name: 'Effective::Order'

    log_changes if respond_to?(:log_changes)

    has_many :qb_receipt_items, inverse_of: :qb_receipt, dependent: :delete_all
    accepts_nested_attributes_for :qb_receipt_items

    acts_as_statused(:ready, :completed, :errored)

    effective_resource do
      # QuickBooks SalesReceipt
      customer_id               :integer
      deposit_to_account_id     :integer
      payment_method_id         :integer

      # Any error message from our sync
      result                    :text

      # Acts as Statused
      status                    :string
      status_steps              :text

      timestamps
    end

    scope :deep, -> { includes(:order, :qb_receipt_items) }

    def to_s
      order.to_s
    end

    # Find or build
    def qb_receipt_item(order_item:)
      qb_receipt_items.find { |item| item.order_item == order_item } ||
      qb_receipt_items.build(order_item: order_item)
    end

  end
end
