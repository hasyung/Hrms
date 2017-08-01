class DinnerSettle < ActiveRecord::Base
  COLUMNS = %w(month employee_id employee_no employee_name location shifts_type area card_amount card_number working_fee backup_fee subsidy_amount total)

  IMPORTOR_TYPE = {
    "北头股份明细表" => :import_north_part_detail,
    "北头股份总表" => :import_north_part_total,
    "机关股份明细" => :import_office_detail,
    "机关股份总表" => :import_office_total,
    "重庆食堂充值表" => :import_cq_charge_table,
    "昆明食堂充值表" => :import_km_charge_table
  }

  COMPUTE_TYPE = {
    "饭卡数据" => :compute_meal_area,
    "重庆和昆明食堂数据" => :compute_cq_km_area
  }

  EXPORTOR_TYPE = {
    "食堂拨付表" => :export_pay_table,
    "重庆食堂拨付表" => :export_cq_pay_table,
    "昆明食堂拨付表" => :export_km_pay_table
  }
end
