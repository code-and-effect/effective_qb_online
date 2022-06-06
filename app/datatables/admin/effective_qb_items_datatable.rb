module Admin
  class EffectiveQbItemsDatatable < Effective::Datatable
    datatable do
      col :id, label: 'QuickBooks Item Id'
      col :name, label: 'QuickBooks Item Name'
      col :fully_qualified_name, label: 'QuickBooks Fully Qualified Name'
    end

    collection do
      EffectiveQbOnline.api.items.map do |item|
        [item.id, item.name, item.fully_qualified_name]
      end
    end

  end
end
