class AddColumnForFlows < ActiveRecord::Migration
  def change
    if Flow.attribute_names.exclude?("leave_date_record")
      add_column :flows, :leave_date_record, :text, index: true
    end
  end
end
