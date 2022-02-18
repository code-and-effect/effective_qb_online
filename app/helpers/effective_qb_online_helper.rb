module EffectiveQbOnlineHelper
  def qb_receipt_effective_orders_collection(qb_receipt)
    raise('expected a non-persisted Effective::QbReceipt') unless qb_receipt.kind_of?(Effective::QbReceipt) && qb_receipt.new_record?

    existing = Effective::QbReceipt.select('order_id')
    orders = Effective::Order.purchased.sorted.includes(:user).where.not(id: existing)

    orders.map do |order|
      label = "#{order} - #{order.user} - #{price_to_currency(order.total)}"
      [label, order.to_param]
    end

  end
end
