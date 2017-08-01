class AddServiceCDrivingBaseSalary < ActiveRecord::Migration
  def change
  	service_c_driving_base = {
      "flag_list" => ["amount", "X"],
      "flag_names" => {
        "amount" => "金额",
        "X" => "X"
      },
      "flags" => {
        "1" => {
          "amount" => 2100,
          "X" => {
            "grade_list" => [1],
            "bg_color" => "white",
            "format_cell" => "默认",
            "transfer_years" => 0,
            "expr" => ""
          }
        }
      }
    }

		salary = Salary.find_or_create_by(category: 'service_c_driving_base', table_type: 'dynamic')
    salary.update(form_data: service_c_driving_base)
  end
end
