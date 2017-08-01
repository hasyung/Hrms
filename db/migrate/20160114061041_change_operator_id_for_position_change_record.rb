class ChangeOperatorIdForPositionChangeRecord < ActiveRecord::Migration
  def change
    add_column :position_change_records, :operator_name, :string

    PositionChangeRecord.where.not(operator_id: nil).each do |pos_change_record|
      operator_name = Employee.unscoped.find_by(id: pos_change_record.operator_id).name
      pos_change_record.update(operator_name: operator_name)
    end
  end
end
