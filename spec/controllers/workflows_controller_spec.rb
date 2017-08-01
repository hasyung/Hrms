require 'rails_helper'

RSpec.describe Api::WorkflowsController, :type => :controller do
  render_views

  let(:json) {JSON.parse(response.body)}

  before(:each) do
    # 构建一级部门
    @root_dep_grade = create(:department_grade)
    @root_dep_nature = create(:department_nature)
    @root_dep = create(:root_department, grade_id: @root_dep_grade.id, nature_id: @root_dep_nature.id)
    # 构建二级部门
    @second_dep_grade = create(:positive_grade)
    @second_dep = create(:second_department, name: '人力资源部', parent_id: @root_dep.id, grade_id: @second_dep_grade.id)

    # 构造岗位数据
    @pos_cat = create(:master_pos_category)
    @pos_channel = create(:channel)
    @basic_pos = create(:position, department_id: @second_dep.id, category_id: @pos_cat.id, channel_id: @pos_channel.id)

    # 构建员工数据
    @employment_status = create(:employment_status)
    @employee = create(:employee, department_id: @second_dep.id, gender_id: create(:gender_male).id)
    EmployeePosition.create(employee_id: @employee.id, position_id: @basic_pos.id)

    # 构建hr劳动关系科科员数据
    @hr_labor_relation_member = create(:hr_labor_relation_member, department_id: @root_department)
    @hr_pos = create(:position, department_id: @root_dep.id, category_id: @pos_cat.id, channel_id: @pos_channel.id)
    EmployeePosition.create(employee_id: @hr_labor_relation_member.id, position_id: @hr_pos.id)

    # 构建一级领导
    @grade_1st_leader = create(:grade_1st_leader, department_id: @root_department)
    @hr_pos = create(:position, department_id: @root_dep.id, category_id: @pos_cat.id, channel_id: @pos_channel.id)
    EmployeePosition.create(employee_id: @grade_1st_leader.id, position_id: @hr_pos.id)

    @rear_pos = create(:position, department_id: @second_dep.id, category_id: @pos_cat.id, channel_id: @pos_channel.id)
    @rear_service_member = create(:rear_service_member)
    @rear_service_leader = create(:rear_service_leader)
    EmployeePosition.create(employee_id: @rear_service_member.id, position_id: @rear_pos.id)
    EmployeePosition.create(employee_id: @rear_service_leader.id, position_id: @rear_pos.id)

    @file = Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'support', 'hrms.jpg'))
    @attachment = create(:flow_attachment, file: @file)

    @flow = create(:flow_women_leave, sponsor_id: @employee.id,
          receptor_id: @employee.id, reviewer_ids: [@employee.id],
          form_data: {start_time: '1999-09-09 00:00:00', vacation_days: 1, reason: '测试女工假'})

    @flow_node = create(:workflow_event, flow_id: @flow.id,
          workflow_state: 'checking',
          reviewer_id: @employee.id,
          reviewer_no: @employee.employee_no,
          reviewer_name: @employee.name,
          reviewer_position: @employee.master_position.name,
          reviewer_department: @employee.department.full_name,
          body: '111')

    # 考勤汇总数据
    create(:attendance_summary_status_manager, department_id: @employee.department_id, department_hr_checked: true)
  end

  after(:each) do
    puts JSON.pretty_generate(json)
  end

  describe 'workflows#node_update' do
    context "with rightful params" do
      it "should update flow_node success" do
        login_as_user(@employee.id)

        patch :node_update, format: :json, flow_type: 'Flow::WomenLeave',
          id: @flow.id,
          node_id: @flow_node.id,
          body: '审批意见'
        expect(response).to be_success
        expect(json["flow_node"]["body"]).to eq('审批意见')
      end
    end
  end

  describe 'workflows#attachments' do
    context "with rightful params" do
      it "should create flow_attachment success" do
        login_as_user(@hr_labor_relation_member.id)

        post :attachments, format: :json, flow_type: 'Flow::WomenLeave',
          file: @file

        expect(response).to be_success
        expect(json["attachment"]["type"].include?('image')).to eq(true)
      end
    end
  end

  describe 'workflows#supplement' do
    context "with rightful params" do
      it "should supplement flow attachments" do
        login_as_user(@employee.id)

        patch :supplement, format: :json, flow_type: 'Flow::WomenLeave',
          id: @flow.id,
          attachment_ids: [@attachment.id]
        expect(response).to be_success
        expect(json["workflow"]["attachments"][0]["id"]).to eq(@attachment.id)
      end
    end
  end

  describe 'workflows#update' do
    context "with reviewer_ids params" do
      it "should update flow success" do
        login_as_user(@employee.id)

        patch :update, format: :json, flow_type: 'Flow::WomenLeave',
          id: @flow.id,
          reviewer_id: @employee.id
        expect(response).to be_success
        expect(json["workflow"]["reviewer_ids"]).to eq([@employee.id])
      end
    end

    context "with opinion params" do
      it "should update flow success" do
        login_as_user(@employee.id)

        patch :update, format: :json, flow_type: 'Flow::WomenLeave',
          id: @flow.id,
          opinion: true
        expect(response).to be_success
        workflow_state = json["workflow"]["workflow_state"]
        expect(workflow_state == 'accepted' || workflow_state == 'actived').to eq(true)
      end
    end
  end

  describe 'workflows#repeal' do
    context "with rightful params" do
      it "should repeal flow success" do
        login_as_user(@employee.id)

        patch :repeal, format: :json, flow_type: 'Flow::WomenLeave',
          id: @flow.id
        expect(response).to be_success
        expect(json["workflow"]["reviewer_ids"]).to eq([])
        expect(json["workflow"]["workflow_state"]).to eq('repeal')
      end
    end
  end

  describe 'workflows#deduct' do
    context 'with wrong flow' do
      it 'should fail with message: this flow is not allowed with deduct' do
        login_as_user(@employee.id)

        patch :deduct, format: :json, flow_type: 'Flow::WomenLeave', id: @flow.id, days: 1
        expect(json["messages"]).to eq("只有事假和病假支持抵扣")
      end
    end

    context 'start_time over 2 month' do
      it 'should fail with message: this flow is over 2 month' do
        login_as_user(@employee.id)
        @flow = create(:flow_sick_leave, sponsor_id: @employee.id,
          receptor_id: @employee.id, reviewer_ids: [@employee.id],
          form_data: {start_time: '2015-03-20 00:00:00', end_time: '2015-03-21 00:00:00', vacation_days: 1, reason: '测试病假'})

        patch :deduct, format: :json, flow_type: 'Flow::SickLeave', id: @flow.id, days: 1
        expect(json["messages"]).to eq("年假抵扣只支持2个月以内的事假和病假")
      end
    end

    context 'deduct days over total_year_days' do
      it "should fail with message: your total_year_days is short" do
        login_as_user(@employee.id)
        @flow = create(:flow_sick_leave, sponsor_id: @employee.id,
          receptor_id: @employee.id, reviewer_ids: [@employee.id],
          form_data: {start_time: DateTime.now, end_time: DateTime.now.advance(days: 5), vacation_days: 5, reason: '测试病假'})

        patch :deduct, format: :json, flow_type: 'Flow::SickLeave', id: @flow.id, days: 100
        expect(json["messages"]).to eq("你的剩余年假不足！")
      end
    end

    context 'with rightful params' do
      it "should be success" do
        login_as_user(@employee.id)
        @flow = create(:flow_sick_leave, sponsor_id: @employee.id, name: '病假',
          receptor_id: @employee.id, reviewer_ids: [@employee.id],
          form_data: {start_time: DateTime.now, end_time: DateTime.now.advance(days: 5), vacation_days: 5, reason: '测试病假'})

        patch :deduct, format: :json, flow_type: 'Flow::SickLeave', id: @flow.id, days: @employee.total_year_days
        # expect(response).to be_success
        expect(json['workflow']['name']).to eq("病假-抵扣")
      end
    end
  end

  describe 'workflows#index' do
    context "without flow_type params" do
      it "should get flow total_count" do
        login_as_user(@employee.id)

        get :index, format: :json
        expect(response).to be_success
        expect(json["workflows"].size).to eq(1)
      end
    end

    context "with leave params" do
      it "should get leave flows" do
        login_as_user(@employee.id)

        get :index, format: :json, flow_type: 'leave'
        expect(response).to be_success
        expect(json["workflows"][0]["id"]).to eq(@flow.id)
      end
    end

    context "with other flow_type params" do
      it "should get other flows" do
        login_as_user(@employee.id)

        get :index, format: :json, flow_type: 'Flow::WomenLeave'
        expect(response).to be_success
        expect(json["workflows"][0]["id"]).to eq(@flow.id)
      end
    end
  end

  describe 'workflows#record' do
    context "with leave params" do
      it "should get leave flows" do
        login_as_user(@employee.id)

        patch :update, format: :json, flow_type: 'Flow::WomenLeave',
          id: @flow.id,
          opinion: true

        get :record, format: :json, flow_type: 'leave'
        expect(response).to be_success
        expect(json["workflows"][0]["id"]).to eq(@flow.id)
      end
    end

    context "with other flow_type params" do
      it "should get other flows" do
        login_as_user(@employee.id)

        patch :update, format: :json, flow_type: 'Flow::WomenLeave',
          id: @flow.id,
          opinion: true

        get :record, format: :json, flow_type: 'Flow::WomenLeave'
        expect(response).to be_success
        expect(json["workflows"][0]["id"]).to eq(@flow.id)
      end
    end
  end

  describe 'workflows#show' do
    context "with rightful params" do
      it "should get a flow" do
        login_as_user(@employee.id)

        get :show, format: :json, flow_type: 'Flow::WomenLeave',
          id: @flow.id
        expect(response).to be_success
        expect(json["workflow"]["id"]).to eq(@flow.id)
      end
    end
  end

  describe 'workflows#transfer_to_occupation_injury' do
    context 'sick leave injury to occupation injury' do
      it "should be success" do
        login_as_user(@employee.id)
        @flow = create(:flow_sick_leave_injury, sponsor_id: @employee.id, receptor_id: @employee.id,
          start_time: '2016-06-15', end_time: '2016-06-17', vacation_days: 2, reason: 'xxx')
        @flow.active

        put :transfer_to_occupation_injury, format: :json, flow_type: 'Flow::SickLeaveInjury', id: @flow.id

        expect(response).to be_success
        expect(json["workflow"]["name"]).to eq("病假(工伤待定)-工伤假")
      end
    end

    context 'other flow(exclude sick leave injury) to occupation injury' do
      it "should be fail" do
        login_as_user(@employee.id)
        @flow = create(:flow_sick_leave, sponsor_id: @employee.id, name: '病假',
          receptor_id: @employee.id, reviewer_ids: [@employee.id],
          form_data: {start_time: '2015-04-20 00:00:00', end_time: '2015-04-25 00:00:00', vacation_days: 5, reason: '测试病假'})
        @flow.active

        put :transfer_to_occupation_injury, format: :json, flow_type: 'Flow::SickLeave', id: @flow.id

        expect(response.code).to eq('400')
        expect(json["messages"]).to eq("只有工伤待定才能转工伤")
      end
    end
  end

end
