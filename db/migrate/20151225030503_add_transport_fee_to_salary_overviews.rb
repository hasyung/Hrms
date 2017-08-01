class AddTransportFeeToSalaryOverviews < ActiveRecord::Migration
  def change
    add_column :salary_overviews, :transport_fee, :decimal, precision: 10, scale: 2, default: 0, index: true, comment: '交通费'
  end
end
