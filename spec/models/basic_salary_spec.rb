require 'rails_helper'

RSpec.describe BasicSalary, type: :model do
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

    @employee = create(:employee, department_id: @dep.id)
    EmployeePosition.create(employee_id: @employee.id, position_id: @pos.id)

    @salary_setup = SalaryPersonSetup.create({employee_id: @employee.id})

    @month = "2015-09"
    @total_money = 6580
    @compute_month = Date.parse(@month + "-01").prev_month.strftime("%Y-%m")

    @salary_setup.base_wage = 'leader_base'
    @salary_setup.base_flag = '7'
    @salary_setup.base_money = 6580
    @salary_setup.save

    form_data1 = {
      "dollar_rate" => 6.12345,             #float, 美元汇率
      "minimum_wage" => 1200.00,            #float, 最低工资
      "average_wage" => 2400.00,            #float, 平均工资
      "basic_cardinality" => 1400,   #integer, 薪酬基数(基本工资)
      "coefficient" => {  #月度绩效系数
          "2015-09" => {
              "perf_execute" => 500,          #integer, 公司
              "business_council" => 400,      #integer, 商委
              "logistics" => 300              #integer, 物流
          }
      }
    }

    Salary.create(category: 'global', table_type: 'static', form_data: form_data1)

    AttendanceSummaryStatusManager.create(summary_date: @compute_month, hr_department_leader_checked: true)
    @summary = AttendanceSummary.create({employee_id: @employee.id, summary_date: @compute_month})
  end

  describe "BasicSalary#compute" do
    context "with right condition" do
      it "should get the right value" do
        BasicSalary.compute(@month)
        expect(BasicSalary.first.total).to eq(@total_money)
        puts CalcStep.all.map(&:step_notes)
      end
    end
  end

  describe "BasicSalary#compute" do
    context "with attendance_summary condition" do
      it "should get the right value" do
        @summary.update(late_or_leave: '2', personal_leave: '5')

        BasicSalary.compute(@month)
        expect(BasicSalary.first.total).to eq(@total_money - (@total_money*0.3).round(2) - (@total_money*(5/21.75)).round(2))
        puts CalcStep.all.map(&:step_notes)
      end
    end
  end
end
