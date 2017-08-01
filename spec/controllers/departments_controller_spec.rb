require 'rails_helper'

RSpec.describe Api::DepartmentsController, :type => :controller do
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
    it "should create new department successfully" do
      @department_name = Faker::Name.name
      @department_count = Department.count

      expect{
        login_as_user(@employee.id)
        post :create, format: :json, name: @department_name, parent_id: @root_dep.id, grade_id: @second_dep_grade.id, nature_id: @second_dep_nature.id, location: "成都", node_type: "二正级"
      }.to change(Action, :count).by(1)
    end

    it "should update department" do
      login_as_user(@employee.id)

      expect{
        @department = create(:second_department, parent_id: @root_dep.id, grade_id: @second_dep_grade.id)
        patch :update, format: :json, id: @department.id, name: Faker::Name.name
        expect(response).to be_success
      }.to change(Action, :count).by(1)
    end

    it "should list departmentss" do
      login_as_user(@employee.id)
      get :index, format: :json
      expect(response).to be_success
    end

    it "should show department" do
      login_as_user(@employee.id)
      get :show, format: :json, id: @second_dep.id
      expect(response).to be_success
    end

    it "should active actions" do
      login_as_user(@employee.id)

      @department = create(:second_department, parent_id: @root_dep.id, grade_id: @second_dep_grade.id)
      patch :update, format: :json, id: @department.id, name: Faker::Name.name

      post :active, format: :json, department_id: @root_dep.id, title: Faker::Name.name, oa_file_no: "2015_file_no"
      expect(response).to be_success
    end

    it "should revert actions" do
      login_as_user(@employee.id)

      @department = create(:second_department, parent_id: @root_dep.id, grade_id: @second_dep_grade.id)
      patch :update, format: :json, id: @department.id, name: Faker::Name.name

      post :revert, format: :json
      expect(response).to be_success
    end

    it "list change_logs" do
      login_as_user(@employee.id)

      @department = create(:second_department, parent_id: @root_dep.id, grade_id: @second_dep_grade.id)
      patch :update, format: :json, id: @department.id, name: Faker::Name.name
      post :active, format: :json, department_id: @root_dep.id, title: Faker::Name.name, oa_file_no: "2015_file_no"

      get :index, format: :json
      expect(response).to be_success
    end

    it "should destroy department" do
      expect{
        login_as_user(@employee.id)
        @department = create(:second_department, parent_id: @root_dep.id, grade_id: @second_dep_grade.id)
        delete :destroy, format: :json, id: @department.id
        expect(response).to be_success
      }.to change(Action, :count).by(1)
    end
  end
end
