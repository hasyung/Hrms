class FixDecimalScaleProblem < ActiveRecord::Migration
  def change
    change_column :basic_salaries, :add_garnishee, :decimal, precision: 10, scale: 2, index: true
    change_column :transport_fees, :amount, :decimal, precision: 10, scale: 2, index: true
    change_column :transport_fees, :add_garnishee, :decimal, precision: 10, scale: 2, index: true
    change_column :transport_fees, :bus_fee, :decimal, precision: 10, scale: 2, index: true
    change_column :allowances, :add_garnishee, :decimal, precision: 10, scale: 2, index: true
    change_column :land_allowances, :subsidy, :decimal, precision: 10, scale: 2, index: true
    change_column :land_allowances, :add_garnishee, :decimal, precision: 10, scale: 2, index: true

    change_column :rewards, :flight_bonus, :decimal, precision: 10, scale: 2, index: true
    change_column :rewards, :service_bonus, :decimal, precision: 10, scale: 2, index: true
    change_column :rewards, :ailine_security_bonus, :decimal, precision: 10, scale: 2, index: true
    change_column :rewards, :composite_bonus, :decimal, precision: 10, scale: 2, index: true
    change_column :rewards, :in_out_bonus, :decimal, precision: 10, scale: 2, index: true
    change_column :rewards, :bonus_1, :decimal, precision: 10, scale: 2, index: true
    change_column :rewards, :bonus_2, :decimal, precision: 10, scale: 2, index: true
  end
end
