require 'rails_helper'

RSpec.describe Api::AllowancesController, type: :controller do
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

    @salary = Salary.new(category: 'allowance')
    @form_data = {
      "security_subsidy" => {
        "lower" => 100,
        "middle" => 400,
        "higher" => 600
      },
      "placement_subsidy" => 500,
      "leader_subsidy" => {
        "line_A" => 100,
        "line_B" => 100,
        "line_C" => 100,
        "line_D" => 100,
        "logistics_1" => 100,
        "logistics_2" => 100
      },
      "terminal_subsidy" => {
        "first" => 100,
        "second" => 100
      },
      "car_subsidy" => 500,
      "ground_subsidy" => {
        "first" => 100,
        "second" => 100,
        "third" => 100,
        "fourth" => 100,
        "fifth" => 100,
        "sixth" => 100
      },
      "machine_subsidy" => {
        "first" => 100,
        "second" => 100,
        "third" => 100,
        "fourth" => 100,
        "fifth" => 100
      },
      "trial_subsidy" => {
        "first" => 100,
        "second" => 100
      },
      "honor_subsidy" => {
        "copper" => 100,
        "silver" => 100,
        "gold" => 100,
        "exploit" => 100
      }
    }

    @salary.form_data = @form_data
    @salary.save

    @salary = Salary.new(category: 'temp')
    @form_data = {
      "city_list" => [
        {
          "start_month" => 6,
          "end_month" => 8,
          "cities" => [
            "北京",
            "天津"
          ]
        },
        {
          "start_month" => 6,
          "end_month" => 9,
          "cities" => [
            "成都",
            "昆明",
            "贵阳"
          ]
        },
        {
          "start_month" => 6,
          "end_month" => 10,
          "cities" => [
            "广州",
            "重庆"
          ]
        },
        {
          "start_month" => 3,
          "end_month" => 11,
          "cities" => [
            "三亚",
            "海口"
          ]
        }
      ]
    }

    @salary.form_data = @form_data
    @salary.save

    @salary_person_setup = SalaryPersonSetup.create(employee_id: @employee.id, security_subsidy: '中级', placement_subsidy: true, leader_subsidy: '一线A类', terminal_subsidy: '一类', car_subsidy: true, ground_subsidy: '一类', machine_subsidy: '一档', trial_subsidy: '一类', honor_subsidy: '铜质')
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
