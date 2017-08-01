class AddRangeDateToLandRecords < ActiveRecord::Migration
  def change
    add_column :land_records, :start_date, :date, index: true, comment: '开始日期'
    add_column :land_records, :end_date, :date, index: true, comment: '结束日期'

    LandRecord.all.each do |lr|
      start_date = Date.parse("#{lr.month}-#{lr.start_day}")
      end_date = Date.parse("#{lr.month}-#{lr.end_day}")
      lr.update(start_date: start_date, end_date: end_date)
    end
  end
end
