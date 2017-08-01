require "rails_helper"

RSpec.describe Api::AttendanceSummariesController, type: :controller do
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

    ## 构建三级部门
    @third_dep_grade = create(:secondly_positive_grade)
    @third_dep = create(:third_department, name: '劳动关系管理室', parent_id: @second_dep.id, grade_id: @third_dep_grade.id)

    # 构造岗位数据
    @pos_cat = create(:master_pos_category)
    @pos_channel = create(:channel)
    @basic_pos = create(:position, department_id: @second_dep.id, category_id: @pos_cat.id, channel_id: @pos_channel.id)
    @basic_pos_2 = create(:position, department_id: @third_dep.id, category_id: @pos_cat.id, channel_id: @pos_channel.id)

    # 构建员工数据
    @employment_status = create(:employment_status)
    @employee = create(:employee, department_id: @second_dep.id, gender_id: create(:gender_male).id)
    EmployeePosition.create(employee_id: @employee.id, position_id: @basic_pos.id)

    @employee_2 = create(:employee, department_id: @third_dep.id, gender_id: create(:gender_male).id)
    EmployeePosition.create(employee_id: @employee_2.id, position_id: @basic_pos_2.id)

    # 构造考勤汇总数据
    @status_manager = AttendanceSummaryStatusManager.create(department_id: @second_dep.id, summary_date: '2015-06', department_name: @second_dep.name)

    @status_manager.attendance_summaries.create(employee_id: @employee.id, department_name: @second_dep.name, employee_no: @employee.employee_no, department_id: @second_dep.id)
    @status_manager.attendance_summaries.create(employee_id: @employee.id, department_name: @second_dep.name, employee_no: @employee.employee_no, department_id: @third_dep.id)

    # 伪造permission
    SystemConfig.create(key: 'bits_counter', value: 0)
    Permission.create!(controller: 'attendance_summaries', action: 'hr_leader_check', category: 'attendance_summary')
  end

  after(:each) do
    puts JSON.pretty_generate(json)
  end

  describe "#department_hr_confirm" do
    before(:each) { login_as_user(@employee.id) }

    context "success" do
      it "should change department_hr_checked status" do
        put :department_hr_confirm, summary_date: '2015-06-12'.to_date

        expect(response).to be_success
        expect(json['department_hr_checked']).to eq(true)
      end
    end

    context "fail" do
      it "should return 400 if department_hr_checked is true" do
        AttendanceSummaryStatusManager.first.department_hr_check

        put :department_hr_confirm, summary_date: '2015-06-12'.to_date
        expect(response.code).to eq("400")
        expect(json['messages']).to eq("该月考勤汇总已经确认")
      end
    end
  end

  describe "#department_leader_check" do
    context 'fail' do
      it "should return 该月考勤汇总部门HR还未审核 if department_hr_checked is false" do
        login_as_user(@employee.id)

        put :department_leader_check, summary_date: '2015-06-12'.to_date
        expect(response.code).to eq("400")
        expect(json['messages']).to eq("该月考勤汇总部门HR还未审核")
      end
    end
  end

  describe "#hr_leader_check" do
    context 'fail' do
      it "should return 404 if attendance summary not found" do
        login_as_user(@employee.id)

        put :hr_leader_check, summary_date: '2015-07-12'.to_date
        expect(response.code).to eq("404")
      end
    end
  end

  describe "#check_list" do
    context 'success' do
      it "should return attendance summaries if summary_date is proper" do
        login_as_user(@employee.id)

        get :check_list, summary_date: '2015-06-12'.to_date, format: :json
        expect(response).to be_success
        expect(json['attendance_summaries'][0]['employee_no']).to eq(@employee.employee_no)
      end

      it "should return empty if summary_date is not proper" do
        login_as_user(@employee.id)

        get :check_list, summary_date: '2015-05-12'.to_date, format: :json
        expect(json['attendance_summaries'].empty?).to eq(true)
      end
    end
  end

  describe '#index' do
    context 'search with conditions' do
      it "should return all attendance_summaries when search second_dep" do
        login_as_user(@employee_2.id)

        get :index, department_ids: [@second_dep.id], format: :json
        expect(json['attendance_summaries'].count).to eq(2)
      end
    end
  end
end