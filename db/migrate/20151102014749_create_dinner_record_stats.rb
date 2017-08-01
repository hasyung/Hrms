class CreateDinnerRecordStats < ActiveRecord::Migration
  def change
    create_table :dinner_record_stats do |t|
      t.string :category, index: true, comment: '类别'
      t.string :month, index: true
      t.decimal :employee_charge_total, precision: 10, scale: 2, index: true, comment: '消费总额'
      t.decimal :consume_total, precision: 10, scale: 2, index: true, comment: '职工现金充值总额'
      t.string :airline_pos_list, comment: '空勤食堂pos机列表，包含空勤午餐和空勤晚餐'
      t.string :political_pos_list, comment: '行政食堂pos机列表，包含行政午餐'
      t.timestamps null: false
    end
  end
end
