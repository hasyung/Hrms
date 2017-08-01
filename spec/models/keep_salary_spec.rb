require 'rails_helper'

RSpec.describe KeepSalary, type: :model do
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
    @total_money = 0.99 * 9
    @salary_setup.keep_position = 0.99
    @salary_setup.keep_performance = 0.99
    @salary_setup.keep_working_years = 0.99
    @salary_setup.keep_minimum_growth = 0.99
    @salary_setup.keep_land_allowance = 0.99
    @salary_setup.keep_life_1 = 0.99
    @salary_setup.keep_life_2 = 0.99
    @salary_setup.keep_adjustment_09 = 0.99
    @salary_setup.keep_bus_14 = 0.99
    @salary_setup.keep_communication_14 = 0.99

    @salary_setup.save
  end

  describe "KeepSalary#compute" do
    context "with right condition" do
      it "should sum of the project together" do
        KeepSalary.compute(@month)
        expect(KeepSalary.first.total).to eq(@total_money)
        puts CalcStep.all.map(&:step_notes)
      end
    end
  end
end
