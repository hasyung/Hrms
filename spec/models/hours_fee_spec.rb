require 'rails_helper'

RSpec.describe HoursFee, type: :model do
  before :each do
    # 构建一级部门
    @dep_grade = create(:department_grade)
    @dep_nature = create(:department_nature)
    @dep = create(:root_department, grade_id: @dep_grade.id, nature_id: @dep_nature.id)

    # 构造岗位数据
    @pos_cat = create(:master_pos_category)
    @pos_channel = create(:channel)
    @pos = create(:position, department_id: @dep.id, category_id: @pos_cat.id, channel_id: @pos_channel.id)

    @employee = create(:employee, department_id: @dep.id)
    EmployeePosition.create(employee_id: @employee.id, position_id: @pos.id)

    @salary_setup = SalaryPersonSetup.create({employee_id: @employee.id})

    @month = "2015-09"
    @fly_fee = 3500

    @salary_setup.airline_hour_fee = 'first_class_B'
    @salary_setup.security_hour_fee = 'security_D'
    @salary_setup.save


    @hours_fee = HoursFee.create({employee_id: @employee.id, month: @month, total_hours_fee: 3500, fly_hours: 50})

    flyer_hour = {
      "techer_A" => 420,             # 教员 A
      "techer_B" => 400,             # 教员 B
      "leader_A" => 380,             # 责任机长 A
      "leader_B" => 360,             # 责任机长 B
      "leader" => 240,          # 机 长
      "copilot_special" => 240,      # 副驾驶特别档
      "copilot_1" => 190,            # 副驾驶 1
      "copilot_2" => 165,            # 副驾驶 2
      "copilot_3" => 155,            # 副驾驶 3
      "copilot_4" => 135,            # 副驾驶 4
      "copilot_5" => 130,            # 副驾驶 5
      "copilot_6" => 100,            # 副驾驶 6
      "observer" => 150              # 空中观察员
    }
    Salary.create(category: 'flyer_hour', table_type: 'static', form_data: flyer_hour)

    fly_attendant_hour = {
      'purser_A' => 145,
      'purser_B' => 135,
      'purser_C' => 125,
      'purser_D' => 110,
      'purser_E' => 90,
      'first_class_A' => 75,
      'first_class_B' => 70,
      'attendant_A' => 65,
      'attendant_B' => 58,
      'attendant_C' => 52,
      'trainee_A' => 30,
      'trainee_B' => 20
    }
    Salary.create(category: 'fly_attendant_hour', table_type: 'static', form_data: fly_attendant_hour)

    air_security_hour = {
      "security_A" => 145,             # 资深安 A
      "security_B" => 120,             # 资深安 B
      "security_C" => 105,             # 资深安 C
      "security_D" => 85,             # 资深安 D
      "safety_A" => 70,               # 安全员 A
      "safety_B" => 60,               # 安全员 B
      "safety_C" => 55,               # 安全员 C
      "safety_D" => 50,               # 安全员 D
      "noviciate_safety" => 27         # 见习安
    }
    Salary.create(category: 'air_security_hour', table_type: 'static', form_data: air_security_hour)

    service_c_1_perf = {
      "flag_list" => ["amount", "A", "B", "C", "D", "E"],
      "flag_names" => {
        "amount" => "服务C-1",
        "A" => "A",
        "B" => "B",
        "C" => "C",
        "D" => "D",
        "E" => "E"
      },
      "flags" => {
        "1" => {
          "amount" => 1950,
          "D" => {
            "grade_list" => [1, 2, 3],
            "bg_color" => "white",
            "format_cell" => " %{transfer_years} 年及以下",
            "expr" => "%{transfer_years} < 5"
          },
          "E" => {
            "grade_list" => [1, 2],
            "bg_color" => "white",
            "format_cell" => "到岗满 %{transfer_years} 年的次月起",
            "expr" => "%{transfer_years} > 0.25"
          }
        },
        "2" => {
          "amount" => 2200,
          "D" => {
            "grade_list" => [1, 2, 3],
            "bg_color" => "white",
            "format_cell" => "不少于 %{transfer_years} 年",
            "expr" => "%{transfer_years} >= 5"
          },
          "E" => {
            "grade_list" => [1, 2],
            "bg_color" => "white",
            "format_cell" => "到岗满 %{transfer_years} 年的次月起",
            "expr" => "%{transfer_years} > 1"
          }
        },
        "3" => {
          "amount" => 2500,
          "C" => {
            "grade_list" => [3, 5, 7, 9],
            "bg_color" => "white",
            "format_cell" => "不少于 %{transfer_years} 年",
            "expr" => "%{transfer_years} > 2"
          },
          "D" => {
            "grade_list" => [1, 2, 3],
            "bg_color" => "white",
            "format_cell" => "不少于 %{transfer_years} 年",
            "expr" => "%{transfer_years} >= 10"
          }
        },
        "4" => {
          "amount" => 2750,
          "B" => {
            "grade_list" => [4, 7, 10],
            "bg_color" => "white",
            "format_cell" => "不少于 %{transfer_years} 年",
            "expr" => "%{transfer_years} > 2"
          }
        },
        "5" => {
          "amount" => 3000,
          "A" => {
            "grade_list" => [5, 8, 11],
            "bg_color" => "white",
            "format_cell" => "不少于 %{transfer_years} 年",
            "expr" => "%{transfer_years} > 2"
          },
          "C" => {
            "grade_list" => [3, 5, 7, 9],
            "bg_color" => "white",
            "format_cell" => "不少于 %{transfer_years} 年",
            "expr" => "%{transfer_years} > 5"
          }
        },
        "6" => {
          "amount" => 3200
        },
        "7" => {
          "amount" => 3400,
          "B" => {
            "grade_list" => [4, 7, 10],
            "bg_color" => "white",
            "format_cell" => "不少于 %{transfer_years} 年",
            "expr" => "%{transfer_years} > 5"
          },
          "C" => {
            "grade_list" => [3, 5, 7, 9],
            "bg_color" => "white",
            "format_cell" => "不少于 %{transfer_years} 年",
            "expr" => "%{transfer_years} > 10"
          }
        },
        "8" => {
          "amount" => 3600,
          "A" => {
            "grade_list" => [5, 8, 11],
            "bg_color" => "white",
            "format_cell" => "不少于 %{transfer_years} 年",
            "expr" => "%{transfer_years} > 5"
          }
        },
        "9" => {
          "amount" => 3800,
          "C" => {
            "grade_list" => [3, 5, 7, 9],
            "bg_color" => "white",
            "format_cell" => "不少于 %{transfer_years} 年",
            "expr" => "%{transfer_years} > 18"
          }
        },
        "10" => {
          "amount" => 4000,
          "B" => {
            "grade_list" => [4, 7, 10],
            "bg_color" => "white",
            "format_cell" => "不少于 %{transfer_years} 年",
            "expr" => "%{transfer_years} > 10"
          }
        },
        "11" => {
          "amount" => 4200,
          "A" => {
            "grade_list" => [5, 8, 11],
            "bg_color" => "white",
            "format_cell" => "不少于 %{transfer_years} 年",
            "expr" => "%{transfer_years} > 10"
          }
        },
        "12" => {
          "amount" => 4600
        }
      }
    }
    Salary.create(category: 'service_c_1_perf', table_type: 'dynamic', form_data: service_c_1_perf)

    AttendanceSummaryStatusManager.create(summary_date: @month, hr_department_leader_checked: true)
    @summary = AttendanceSummary.create({employee_id: @employee.id, summary_date: @month})
  end


  describe "HoursFee#compute" do
    context "with right condition where hours_fee_category == '飞行员'" do
      it "should get the right value" do
        @hours_fee.update(hours_fee_category: '飞行员')
        HoursFee.compute(@month, '飞行员')
        expect(HoursFee.first.fly_fee).to eq(@fly_fee)
        puts CalcStep.all.map(&:step_notes)
      end
    end

    context "with right condition where hours_fee_category == '飞行员'" do
      it "should get the right value" do
        @hours_fee.update(hours_fee_category: '乘务员')
        HoursFee.compute(@month, '乘务员')
        expect(HoursFee.first.fly_fee).to eq(@fly_fee)
        puts CalcStep.all.map(&:step_notes)
      end
    end

    context "with right condition where hours_fee_category == '飞行员'" do
      it "should get the right value" do
        @hours_fee.update(hours_fee_category: '乘务员')
        @security_hours_fee = HoursFee.create({employee_id: @employee.id, month: @month, total_hours_fee: 4250, fly_hours: 50, 
          hours_fee_category: '安全员', up_or_down: 'up'})

        HoursFee.compute(@month, '安全员')
        expect(HoursFee.find_by(hours_fee_category: '安全员').fly_fee).to eq(4250 + 20*100)
        puts CalcStep.all.map(&:step_notes)
      end
    end
  end
end
