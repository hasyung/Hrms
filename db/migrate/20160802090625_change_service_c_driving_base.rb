class ChangeServiceCDrivingBase < ActiveRecord::Migration
  def change
  	service_c = Salary.find_by(category: 'service_c_driving_base')
  	if service_c
  		form_data = {
	      "flag_list" => ["amount", "X"],
	      "flag_names" => {
	        "amount" => "金额",
	        "X" => "X"
	      },
	      "flags" => {
	        "1" => {
	          "amount" => 2100,
	          "X" => {
	            "grade_list" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
	            "bg_color" => "white",
	            "format_cell" => "默认",
	            "transfer_years" => 0,
	            "expr" => ""
	          }
	        },
	        "2" => {
	          "amount" => 2250,
	          "X" => {
	            "grade_list" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
	            "bg_color" => "white",
	            "format_cell" => "默认",
	            "transfer_years" => 0,
	            "expr" => ""
	          }
	        },
	        "3" => {
	          "amount" => 2450,
	          "X" => {
	            "grade_list" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
	            "bg_color" => "white",
	            "format_cell" => "默认",
	            "transfer_years" => 0,
	            "expr" => ""
	          }
	        },
	        "4" => {
	          "amount" => 2650,
	          "X" => {
	            "grade_list" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
	            "bg_color" => "white",
	            "format_cell" => "默认",
	            "transfer_years" => 0,
	            "expr" => ""
	          }
	        },
	        "5" => {
	          "amount" => 2750,
	          "X" => {
	            "grade_list" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
	            "bg_color" => "white",
	            "format_cell" => "默认",
	            "transfer_years" => 0,
	            "expr" => ""
	          }
	        },
	        "6" => {
	          "amount" => 2850,
	          "X" => {
	            "grade_list" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
	            "bg_color" => "white",
	            "format_cell" => "默认",
	            "transfer_years" => 0,
	            "expr" => ""
	          }
	        },
	        "7" => {
	          "amount" => 2950,
	          "X" => {
	            "grade_list" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
	            "bg_color" => "white",
	            "format_cell" => "默认",
	            "transfer_years" => 0,
	            "expr" => ""
	          }
	        },
	        "8" => {
	          "amount" => 3150,
	          "X" => {
	            "grade_list" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
	            "bg_color" => "white",
	            "format_cell" => "默认",
	            "transfer_years" => 0,
	            "expr" => ""
	          }
	        },
	        "9" => {
	          "amount" => 3450,
	          "X" => {
	            "grade_list" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
	            "bg_color" => "white",
	            "format_cell" => "默认",
	            "transfer_years" => 0,
	            "expr" => ""
	          }
	        },
	        "10" => {
	          "amount" => 3750,
	          "X" => {
	            "grade_list" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
	            "bg_color" => "white",
	            "format_cell" => "默认",
	            "transfer_years" => 0,
	            "expr" => ""
	          }
	        }
	      }
	    }
	    service_c.update(form_data: form_data)
  	end
  end
end
