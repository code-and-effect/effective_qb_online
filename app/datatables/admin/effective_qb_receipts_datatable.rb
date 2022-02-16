module Admin
  class EffectiveQbReceiptsDatatable < Effective::Datatable
    datatable do
      order :updated_at

      col :updated_at, visible: false
      col :created_at, visible: false
      col :id, visible: false

      col :created_at

      col :order, search: :string

      col :sales_receipt_id, label: 'Quickbooks Online' do |receipt|
        if receipt.sales_receipt_id.present?
          link_to("Sales Receipt", api.sales_receipt_url(receipt.sales_receipt_id), target: '_blank')
        end
      end

      col :status
      col :result

      actions_col
    end

    collection do
      Effective::QbReceipt.deep.all
    end

    def api
      @api ||= EffectiveQbOnline.api
    end

  end
end
