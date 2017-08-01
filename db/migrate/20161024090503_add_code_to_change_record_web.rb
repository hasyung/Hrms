class AddCodeToChangeRecordWeb < ActiveRecord::Migration
  def change
    add_column :change_record_webs, :code, :integer, index: true, default: nil
    add_column :change_record_webs, :msg, :string, index: true, default: nil
  end
end
