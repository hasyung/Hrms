require 'rails_helper'

RSpec.describe Api::AttendancesController, type: :controller do
  render_views

  let(:json) {JSON.parse(response.body)}

  before(:each) do
    # 构建一级部门
    @root_dep_grade = create(:department_grade)
    @root_dep_nature = create(:department_nature)
    @root_dep = create(:root_department, grade_id: @root_dep_grade.id, nature_id: @root_dep_nature.id)
    # 构建二级部门
    @second_dep_grade = create(:positive_grade)
    @second_dep = create(:second_department, parent_id: @root_dep.id, grade_id: @second_dep_grade.id)

    # 构造岗位数据
    @pos_cat = create(:master_pos_category)
    @pos_channel = create(:channel)
    @basic_pos = create(:position, department_id: @second_dep.id, category_id: @pos_cat.id, channel_id: @pos_channel.id)

    # 构建员工数据
    @employment_status = create(:employment_status)
    @employee = create(:employee, department_id: @second_dep.id, gender_id: create(:gender_male).id)
    EmployeePosition.create(employee_id: @employee.id, position_id: @basic_pos.id)

    # 构造考勤汇总数据
    @status_manager = AttendanceSummaryStatusManager.create(department_id: @second_dep.id, summary_date: Date.today.strftime("%Y-%m"), department_name: @second_dep.name)

    @status_manager.attendance_summaries.create(employee_id: @employee.id, department_name: @second_dep.name, employee_no: @employee.employee_no, department_id: @second_dep.id)
  end

  after(:each) do
    puts JSON.pretty_generate(json)
  end

  describe "#index" do
    context "with normal list" do
      it "should list attendaces" do
        login_as_user(@employee.id)
        create(:attendance, employee_id: @employee.id)

        get :index, format: :json
        expect(response).to be_success
        expect(json['attendances'].size).to eq(1)
      end
    end

    context "with search condition" do
      it 'should list specially employee_name attendances' do
        login_as_user(@employee.id)
        create(:attendance, employee_id: @employee.id)

        get :index, format: :json, employee_name: @employee.name
        expect(response).to be_success
        expect(json['attendances'].size).to eq(1)
      end
    end
  end

  describe "#create" do
    it "should create attendance successfully" do
      login_as_user(@employee.id)

      expect{
        post :create, format: :json, employee_id: @employee.id, record_type: "迟到", record_date: Time.new.to_date.to_s
      }.to change(Attendance, :count).by(1)
    end
  end

  describe "#update" do
    it "should update attendance record type" do
      login_as_user(@employee.id)
      @attendance = create(:attendance, employee_id: @employee.id, record_type: "迟到")

      patch :update, format: :json, id: @attendance.id, record_type: "旷工"
      expect(response).to be_success
      @attendance.reload
      expect(@attendance.record_type).to eq ("迟到-旷工")
    end
  end

  describe "#destroy" do
    it "should destroy and update record type" do
      login_as_user(@employee.id)
      @attendance = create(:attendance, employee_id: @employee.id, record_type: "迟到")

      delete :destroy, format: :json, id: @attendance.id
      expect(response).to be_success
      @attendance.reload
      expect(@attendance.record_type).to eq ("迟到-删除")
    end
  end
end
