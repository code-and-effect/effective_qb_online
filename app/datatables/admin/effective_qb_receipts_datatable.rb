module Admin
  class EffectiveQbReceiptsDatatable < Effective::Datatable
    datatable do
      order :updated_at

      col :updated_at, visible: false
      col :created_at, visible: false
      col :id, visible: false

      col :updated_at

      col :order, search: :string
      col 'order.purchased_at'

      col :sales_receipt_id, label: 'QB Sales Receipt' do |receipt|
        if receipt.sales_receipt_id.present?
          link_to("Sales Receipt", api.sales_receipt_url(receipt.sales_receipt_id), target: '_blank')
        end
      end

      col :customer_id, label: 'QB Customer' do |receipt|
        if receipt.sales_receipt_id.present?
          link_to("Customer", api.customer_url(receipt.customer_id), target: '_blank')
        end
      end

      col :status
      col :result

      col :order_items, label: 'Purchasable Qb Item Names' do |receipt|
        receipt.order.purchasables.map do |purchasable|
          purchasable_id_name = [purchasable.try(:qb_item_id), purchasable.try(:qb_item_name)].compact
          content_tag(:div, purchasable_id_name.join(' or '), class: "col-resource_item")
        end.join.html_safe
      end

      actions_col
    end

    collection do
      Effective::QbReceipt.deep.all.joins(:order)
    end

    def api
      @api ||= EffectiveQbOnline.api
    end

  end
end
