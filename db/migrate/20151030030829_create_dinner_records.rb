class CreateDinnerRecords < ActiveRecord::Migration
  def change
    create_table :dinner_records do |t|
      t.string :category, index: true, comment: '分类'
      t.string :employee_no, index: true, comment: '饭卡编号'
      t.string :employee_name, index: true, comment: '姓名'
      t.datetime :record_date, index: true, comment: '帐务日期'
      t.string :time_range, index: true, comment: '时段'
      t.string :record_type, index: true, comment: '帐务类型'
      t.string :computer_no, index: true, comment: '计算机号'
      t.string :pos_no, index: true, comment: 'pos机号'
      t.decimal :amount, index: true, precision: 10, scale: 2, comment: '交易金额'
      t.decimal :store_balance, index: true, precision: 10, scale: 2, comment: '库中金额'
      t.timestamps null: false
    end
  end
end
