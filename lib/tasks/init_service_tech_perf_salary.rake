namespace :init do
  desc "添加机务技术薪酬设置静态表"

  task service_tech_perf_salary: :environment do
    form_data = {
      "engineer" => {
        "engineer" => {
          "A" => {
            "grade" => 14,
            "rate" => 6.2,
            "amount" => 8680
          },
          "B" => {
            "grade" => 15,
            "rate" => 6.5,
            "amount" => 9100
          },
          "C" => {
            "grade" => 16,
            "rate" => 6.8,
            "amount" => 9520
          },
          "D" => {
            "grade" => 17,
            "rate" => 7.3,
            "amount" => 10220
          },
          "E" => {
            "grade" => 18,
            "rate" => 7.8,
            "amount" => 10920
          },
          "F" => {
            "grade" => 19,
            "rate" => 8.7,
            "amount" => 12180
          },
          "G" => {
            "grade" => 20,
            "rate" => 9.3,
            "amount" => 13020
          }
        }
      },

      "maintain_145" => {
        "captain" => {
          "A" => {
            "grade" => 18,
            "rate" => 7.8,
            "amount" => 10920,
            "position_name" => "分队长"
          },
          "B" => {
            "grade" => 19,
            "rate" => 8.7,
            "amount" => 12180,
            "position_name" => "分队长"
          },
          "C" => {
            "grade" => 20,
            "rate" => 9.3,
            "amount" => 13020,
            "position_name" => "分队长"
          }
        },

        "vice_captain" => {
          "A" => {
            "grade" => 17,
            "rate" => 7.3,
            "amount" => 10220,
            "position_name" => "副分队长"
          },
          "B" => {
            "grade" => 18,
            "rate" => 7.8,
            "amount" => 10920,
            "position_name" => "副分队长"
          },
          "C" => {
            "grade" => 19,
            "rate" => 8.7,
            "amount" => 12180,
            "position_name" => "副分队长"
          }
        }
      },

      "airbus" => {
        "captain" => {
          "A" => {
            "grade" => 17,
            "rate" => 7.3,
            "amount" => 10220,
            "position_name" => "分队长"
          },
          "B" => {
            "grade" => 18,
            "rate" => 7.8,
            "amount" => 10920,
            "position_name" => "分队长"
          },
          "C" => {
            "grade" => 19,
            "rate" => 8.7,
            "amount" => 12180,
            "position_name" => "分队长"
          }
        },

        "vice_captain" => {
          "A" => {
            "grade" => 16,
            "rate" => 6.8,
            "amount" => 9520,
            "position_name" => "副分队长"
          },
          "B" => {
            "grade" => 17,
            "rate" => 7.3,
            "amount" => 10220,
            "position_name" => "副分队长"
          },
          "C" => {
            "grade" => 18,
            "rate" => 7.8,
            "amount" => 10920,
            "position_name" => "副分队长"
          }
        },

        "machinist" => {
          "A" => {
            "grade" => 14,
            "rate" => 6.2,
            "amount" => 8680,
            "position_name" => "机械师"
          },
          "B" => {
            "grade" => 15,
            "rate" => 6.5,
            "amount" => 9100,
            "position_name" => "机械师"
          },
          "C" => {
            "grade" => 16,
            "rate" => 6.8,
            "amount" => 9520,
            "position_name" => "机械师"
          }
        }
      }
    }

    salary = Salary.find_by(category: 'service_tech_perf', table_type: 'static')

    if salary
      salary.update(form_data: form_data)
    else
      Salary.create(category: 'service_tech_perf', table_type: 'static', form_data: form_data)
    end
  end
end
