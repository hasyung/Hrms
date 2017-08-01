require 'rails_helper'

RSpec.describe Api::BirthAllowancesController, type: :controller do
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
  end

  after(:each) do
    puts JSON.pretty_generate(json)
  end

  describe "with action" do
    it "should index" do
      login_as_user(@employee.id)

      create(:birth_allowance)
      get :index, format: :json
      expect(response).to be_success
    end

    it "should create" do
      login_as_user(@employee.id)

      expect{
        login_as_user(@employee.id)
        post :create, format: :json, birth_allowance: {employee_id: @employee.id, employee_no: @employee.employee_no, employee_name: @employee.name, department_name: @employee.department.full_name, position_name: @employee.master_position.name, sent_date: '2015-10-22', sent_amount: 10000, deduct_amount: 5000}
        expect(response).to be_success
      }.to change(BirthAllowance, :count).by(1)
    end

    it "should update" do
      login_as_user(@employee.id)
      @birth_allowance = create(:birth_allowance)

      patch :update, format: :json, id: @birth_allowance.id, birth_allowance: {deduct_amount: 8000}
      expect(response).to be_success
      expect(BirthAllowance.first.deduct_amount).to eq(8000)
    end
  end
end
