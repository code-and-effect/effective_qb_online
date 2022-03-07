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

      # QuickBooks Online SalesReceipt id, once sync'd
      sales_receipt_id          :string

      # Any error message from our sync
      result                    :text

      # Acts as Statused
      status                    :string
      status_steps              :text

      timestamps
    end

    scope :deep, -> { includes(order: :user, qb_receipt_items: [order_item: :purchasable]) }

    # Create a QbReceiptItem for each OrderItem
    before_validation(if: -> { order.present? }) do
      order.order_items.each { |order_item| qb_receipt_item(order_item: order_item) }
    end

    validates :qb_receipt_items, presence: true

    with_options(if: -> { completed? }) do
      validates :customer_id, presence: true
      validates :sales_receipt_id, presence: true
    end

    # Create a QbReceipt from an Effective::Order
    def self.create_from_order!(order)
      raise('Expected a purchased Effective::Order') unless order.kind_of?(Effective::Order) && order.purchased?
      Effective::QbReceipt.where(order: order).first_or_create
    end

    def to_s
      order.to_s
    end

    # Find or build
    def qb_receipt_item(order_item:)
      qb_receipt_items.find { |item| item.order_item == order_item } ||
      qb_receipt_items.build(order_item: order_item)
    end

    def sync!(force: false)
      raise('Already created SalesReceipt with QuickBooks Online') if sales_receipt_id.present? && !force
      save!

      api = EffectiveQbOnline.api

      begin
        sales_receipt = Effective::QbSalesReceipt.build_from_receipt!(self, api: api)
        sales_receipt = api.create_sales_receipt(sales_receipt: sales_receipt)

        # Sanity check
        if (expected = api.price_to_amount(order.total)) != sales_receipt.total
          raise("A QuickBooks Online Sales Receipt has been created with an unexpected total. QuickBooks total is #{sales_receipt.total} but we expected #{expected}. Please adjust the Sales Receipt on QuickBooks")
        end

        assign_attributes(result: 'completed successfully', sales_receipt_id: sales_receipt.id)
        complete!
      rescue => e
        result = [e.message, *("(intuit_tid: #{e.intuit_tid})" if e.try(:intuit_tid).present?)].join(' ')
        assign_attributes(result: result)
        error!
      end

      true
    end

    def skip!
      assign_attributes(result: 'skipped')
      skipped!
    end

    def complete!
      completed!
    end

    def error!
      errored!
    end

  end
end
