require 'rails_helper'

RSpec.describe PerformanceSalary, type: :model do
  before :each do
    # 从develop导入薪酬全局设置数据
    # sql_file = "spec/support/salary.sql"
    # config = YAML.load(File.read(Rails.root.to_s + "/config/database.yml"))[Rails.env]
    # mysql_user = config["username"]

    # `mysqldump -t Hrms_development salaries -u#{mysql_user} > #{sql_file}`
    # IO.write(sql_file, File.open(sql_file){|f|f.read.gsub('Hrms_development', 'Hrms_test')})
    # `mysql -u#{mysql_user} --database Hrms_test < #{sql_file}`
    # `rm #{sql_file}`

    # 构建一级部门
    @dep_grade = create(:department_grade)
    @dep_nature = create(:department_nature)
    @dep = create(:root_department, grade_id: @dep_grade.id, nature_id: @dep_nature.id)

    # 构造岗位数据
    @pos_cat = create(:master_pos_category)
    @pos_channel = create(:channel)
    @schedule = Schedule.create({display_name: '综合工时制', name: '综合工时制'})
    @pos = create(:position, department_id: @dep.id, category_id: @pos_cat.id, channel_id: @pos_channel.id, schedule_id: @schedule.id)

    @category = CodeTable::Category.create({display_name: '干部', name: 'ganbu'})
    @channel = CodeTable::Channel.create({display_name: '空勤', name: 'kongqin'})
    @duty_rank = Employee::DutyRank.create({display_name: '二正', name: 'erzheng'})

    @employee = create(:employee, department_id: @dep.id)
    EmployeePosition.create(employee_id: @employee.id, position_id: @pos.id)

    @salary_setup = SalaryPersonSetup.create({employee_id: @employee.id})

    @month = "2015-09"
    @base_salary = 7280
    @total_money = 9000

    @salary_setup.performance_wage = 'information_perf'
    @salary_setup.performance_flag = '12'
    @salary_setup.performance_money = 7280
    @salary_setup.save

    form_data1 = {
      "dollar_rate" => 6.12345,             #float, 美元汇率
      "minimum_wage" => 1200.00,            #float, 最低工资
      "average_wage" => 2400.00,            #float, 平均工资
      "basic_cardinality" => 1400,   #integer, 薪酬基数(基本工资)
      "coefficient" => {  #月度绩效系数
          "2015-09" => {
              "perf_execute" => 1,          #integer, 公司
              "business_council" => 1,      #integer, 商委
              "logistics" => 1              #integer, 物流
          }
      }
    }
    Salary.create(category: 'global', table_type: 'static', form_data: form_data1)

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

    service_c_2_perf = {
      "flag_list" => ["amount", "A", "B", "C", "D", "E"],
      "flag_names" => {
        "amount" => "服务C-2",
        "A" => "A",
        "B" => "B",
        "C" => "C",
        "D" => "D",
        "E" => "E"
      },
      "flags" => {
        "1" => {
          "amount" => 1800,
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
          "amount" => 2050,
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
          "amount" => 2300,
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
          "amount" => 2550,
          "B" => {
            "grade_list" => [4, 7, 10],
            "bg_color" => "white",
            "format_cell" => "不少于 %{transfer_years} 年",
            "expr" => "%{transfer_years} > 2"
          }
        },
        "5" => {
          "amount" => 2800,
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
          "amount" => 3000
        },
        "7" => {
          "amount" => 3200,
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
          "amount" => 3400,
          "A" => {
            "grade_list" => [5, 8, 11],
            "bg_color" => "white",
            "format_cell" => "不少于 %{transfer_years} 年",
            "expr" => "%{transfer_years} > 5"
          }
        },
        "9" => {
          "amount" => 3550,
          "C" => {
            "grade_list" => [3, 5, 7, 9],
            "bg_color" => "white",
            "format_cell" => "不少于 %{transfer_years} 年",
            "expr" => "%{transfer_years} > 18"
          }
        },
        "10" => {
          "amount" => 3700,
          "B" => {
            "grade_list" => [4, 7, 10],
            "bg_color" => "white",
            "format_cell" => "不少于 %{transfer_years} 年",
            "expr" => "%{transfer_years} > 10"
          }
        },
        "11" => {
          "amount" => 4000,
          "A" => {
            "grade_list" => [5, 8, 11],
            "bg_color" => "white",
            "format_cell" => "不少于 %{transfer_years} 年",
            "expr" => "%{transfer_years} > 10"
          }
        },
        "12" => {
          "amount" => 4200
        }
      }
    }
    Salary.create(category: 'service_c_2_perf', table_type: 'dynamic', form_data: service_c_2_perf)

    AttendanceSummaryStatusManager.create(summary_date: @month, hr_department_leader_checked: true)
    @summary = AttendanceSummary.create({employee_id: @employee.id, summary_date: @month})
  end


  describe "PerformanceSalary#cal_base_salary and #cal_salary" do
    context "with right condition" do
      it "should get the right value" do
        PerformanceSalary.cal_base_salary(@month)
        PerformanceSalary.first.update(department_distribute: 8000, department_reserved: 1000)
        PerformanceSalary.cal_salary(@month)

        expect(PerformanceSalary.first.base_salary).to eq(@base_salary)
        expect(PerformanceSalary.first.total).to eq(@total_money)
        puts CalcStep.all.map(&:step_notes)
      end
    end

    context "with attendance_summary condition" do
      it "should get the right value" do
        @summary.update(personal_leave: '2')

        PerformanceSalary.cal_base_salary(@month)
        PerformanceSalary.first.update(department_distribute: 8000, department_reserved: 1000)
        PerformanceSalary.cal_salary(@month)

        deduct_money = ((2/21.75)*@base_salary).round(2)
        expect(PerformanceSalary.first.base_salary).to eq(@base_salary - deduct_money)
        expect(PerformanceSalary.first.total).to eq(@total_money)
        puts CalcStep.all.map(&:step_notes)
      end
    end

    context "with kongqin condition" do
      it "should get the right value" do
        @employee.update(category_id: @category.id, channel_id: @channel.id, duty_rank_id: @duty_rank.id)
        @salary_setup.update(airline_attendant_type: 'land')

        PerformanceSalary.cal_base_salary(@month)
        PerformanceSalary.first.update(department_distribute: 8000, department_reserved: 1000)
        PerformanceSalary.cal_salary(@month)

        expect(PerformanceSalary.first.base_salary).to eq(PerformanceSalary::CHECK_EARNING_STANDARD['二正'])
        expect(PerformanceSalary.first.total).to eq(0)
        puts CalcStep.all.map(&:step_notes)
      end
    end
  end
end
