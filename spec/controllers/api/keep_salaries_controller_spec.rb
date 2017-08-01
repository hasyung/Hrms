require 'rails_helper'

RSpec.describe Api::KeepSalariesController, type: :controller do
  render_views

  let(:json) {JSON.parse(response.body)}

  before(:each) do
    # 构建一级部门
    @root_dep_grade = create(:department_grade)
    @root_dep_nature = create(:department_nature)
    @root_dep = create(:root_department,
                       grade_id: @root_dep_grade.id,
                       nature_id: @root_dep_nature.id)

    # 构建二级部门
    @second_dep_grade = create(:positive_grade)
    @second_dep_nature = create(:department_nature)
    @second_dep = create(:second_department, parent_id: @root_dep.id, grade_id: @second_dep_grade.id)

    # 构造岗位数据
    @pos_cat = create(:master_pos_category)
    @pos_channel = create(:channel)
    @basic_pos = create(:position, department_id: @second_dep.id, category_id: @pos_cat.id, channel_id: @pos_channel.id)

    # 构建员工数据
    @employment_status = create(:employment_status)
    @employee = create(:employee, department_id: @second_dep.id, gender_id: create(:gender_male).id)
    EmployeePosition.create(employee_id: @employee.id, position_id: @basic_pos.id)
    @month = "2015-11"

    @salary_person_setup = SalaryPersonSetup.create(employee_id: @employee.id, keep_position: 1, keep_performance: 1, keep_working_years: 1, keep_minimum_growth: 1, keep_land_allowance: 1, keep_life_allowance: 1, keep_adjustment_09: 1, keep_bus_14: 1, keep_communication_14: 1)
  end

  after(:each) do
    puts JSON.pretty_generate(json)
  end

  describe "with action" do
    it "should compute" do
      login_as_user(@employee.id)

      allow(SalaryPersonSetup).to receive(:check_compute).and_return(nil)
      allow(AttendanceSummary).to receive(:can_calc_salary?).and_return([true, ""])
      get :compute, format: :json, month: @month
      expect(response).to be_success
      puts response.body

      get :index, format: :json
      expect(response).to be_success
    end
  end
end
