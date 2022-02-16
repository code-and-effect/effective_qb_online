module Effective
  class QbReceipt < ActiveRecord::Base
    belongs_to :order, class_name: 'Effective::Order'

    log_changes if respond_to?(:log_changes)

    has_many :qb_receipt_items, inverse_of: :qb_receipt, dependent: :delete_all
    accepts_nested_attributes_for :qb_receipt_items

    acts_as_statused(:todo, :completed, :errored, :skipped)

    effective_resource do
      # QuickBooks Customer
      customer_id               :string

      # Quickbooks Online SalesReceipt id, once sync'd
      sales_receipt_id          :string

      # Any error message from our sync
      result                    :text

      # Acts as Statused
      status                    :string
      status_steps              :text

      timestamps
    end

    scope :deep, -> { includes(order: :user, qb_receipt_items: [order_item: :purchasable]) }

    validates :qb_receipt_items, presence: true

    with_options(if: -> { completed? }) do
      validates :customer_id, presence: true
      validates :sales_receipt_id, presence: true
    end

    # Create a QbReceipt from an Effective::Order
    def self.create_from_order!(order)
      raise('expected an Effective::Order') unless order.kind_of?(Effective::Order)

      qb_receipt = Effective::QbReceipt.where(order: order).first_or_initialize

      order.order_items.each do |order_item|
        qb_receipt_item = qb_receipt.qb_receipt_item(order_item: order_item)

        # Assign the item ID if we know it right away
        qb_receipt_item.item_id ||= order_item.purchasable.try(:qb_item_id)
      end

      qb_receipt.save!
      qb_receipt
    end

    def to_s
      order.to_s
    end

    # Find or build
    def qb_receipt_item(order_item:)
      qb_receipt_items.find { |item| item.order_item == order_item } ||
      qb_receipt_items.build(order_item: order_item)
    end

    def sync!
      save!

      api = EffectiveQbOnline.api

      begin
        sales_receipt = Effective::QbSalesReceipt.build_from_receipt!(receipt: self, api: api)
        sales_receipt = api.create_sales_receipt(sales_receipt: sales_receipt)

        assign_attributes(result: 'completed successfully', sales_receipt_id: sales_receipt.id)
        complete!
      rescue => e
        assign_attributes(result: e.message)
        error!
      end

      true
    end

    def complete!
      completed!
    end

    def error!
      errored!
    end

  end
end
