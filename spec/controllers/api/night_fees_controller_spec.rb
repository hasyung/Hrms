require 'rails_helper'

RSpec.describe Api::NightFeesController, type: :controller do
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

    @salary_person_setup = SalaryPersonSetup.create(employee_id: @employee.id, security_subsidy: '中级', placement_subsidy: true, leader_subsidy: '一线A类', terminal_subsidy: '一类', car_subsidy: true, ground_subsidy: '一类', machine_subsidy: '一档', trial_subsidy: '一类', honor_subsidy: '铜质')
    @night_record = create(:night_record, employee_no: @employee.employee_no, employee_name: @employee.name, month: @month)
  end

  after(:each) do
    puts JSON.pretty_generate(json)
  end

  describe "with action" do
    it "should compute" do
      login_as_user(@employee.id)

      get :compute, format: :json, month: @month
      expect(response).to be_success
      puts response.body

      get :index, format: :json, month: @month
      expect(response).to be_success
    end
  end
end
