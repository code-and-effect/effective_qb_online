class QbSyncOrderJob < ApplicationJob
  queue_as :default

  def perform(order)
    raise('expected a purchased Effective::Order') unless order.kind_of?(Effective::Order) && order.purchased?

    puts "Starting QB Sync Order Job for order #{order}"

    qb_receipt = Effective::QbReceipt.create_from_order!(order)
    qb_receipt.sync!
  end

end
