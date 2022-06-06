module Admin
  class EffectiveQbItemsDatatable < Effective::Datatable
    datatable do
      col :name, label: 'QuickBooks Item Name'
      col :id, label: 'QuickBooks Item Id'
    end

    collection do
      EffectiveQbOnline.api.items_collection.values.flatten(1)
    end

  end
end
