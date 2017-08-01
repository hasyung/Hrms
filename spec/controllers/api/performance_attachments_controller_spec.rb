require 'rails_helper'

RSpec.describe Api::PerformanceAttachmentsController, type: :controller do
  render_views
  before(:all) do
    DatabaseCleaner.start
    # 构建人力资源部
    @root_dep_grade  = create(:department_grade)
    @root_dep_nature = create(:department_nature)
    @root_dep        = create(
      :root_department,
      grade_id: @root_dep_grade.id,
      nature_id: @root_dep_nature.id,
      name: '人力资源部',
      serial_number: "000009"
    )

    # 构建二级部门
    @second_dep_grade = create(:positive_grade)
    @second_dep       = create(
      :second_department,
      parent_id: @root_dep.id,
      grade_id: @second_dep_grade.id,
      serial_number: "000009001"
    )

    # 构造岗位数据
    @pos_cat     = create(:master_pos_category)
    @pos_channel = create(:channel)
    @basic_pos   = create(
      :position,
      department_id: @second_dep.id,
      category_id: @pos_cat.id,
      channel_id: @pos_channel.id
    )

    @hr_employee = create(
      :employee,
      department_id: @second_dep.id,
      gender_id: create(:gender_male).id
    )

    EmployeePosition.create(
      employee_id: @hr_employee.id,
      position_id: @basic_pos.id
    )

    # 构建其他一级部门
    @other_dep_grade  = create(:department_grade)
    @other_dep_nature = create(:department_nature)
    @other_dep        = create(
      :root_department,
      grade_id: @other_dep_grade.id,
      nature_id: @other_dep_nature.id,
      serial_number: '000098'
    )

    # 构建二级部门
    @other_second_dep_grade = create(:positive_grade)
    @other_second_dep       = create(
      :second_department,
      parent_id: @other_dep.id,
      grade_id: @other_second_dep_grade.id,
      serial_number: "000098001"
    )

    # 构造岗位数据
    @other_pos_cat     = create(:master_pos_category)
    @other_pos_channel = create(:channel)
    @other_basic_pos   = create(
      :position,
      department_id: @other_second_dep.id,
      category_id: @other_pos_cat.id,
      channel_id: @other_pos_channel.id
    )

    FlowRelation.create(
      role_name: 'department_hr',
      position_ids: [] << @other_basic_pos.id.to_s,
      department_id: @other_dep.id
    )

    @employee = create(
      :employee,
      department_id: @other_second_dep.id,
      pcategory: ["员工","基层干部","中层干部","主官"].sample
    )

    EmployeePosition.create(
      employee_id: @employee.id,
      position_id: @other_basic_pos.id
    )

    @employee_performance = create(
      :performance,
      result: ['优秀','良好','合格','待改进','不合格','无'].sample,
      assess_time: Date.today().to_s,
      category: ["year","season","month"].sample,
      employee_name: @employee.name,
      employee_id: @employee.id,
      employee_no: @employee.employee_no
    )

    @hr_performance = create(
      :performance,
      result: ['优秀', '良好', '合格', '待改进', '不合格', '无'].sample,
      assess_time: Date.today().to_s,
      category: ["year","season","month"].sample,
      employee_name: @hr_employee.name,
      employee_id: @hr_employee.id,
      employee_no: @hr_employee.employee_no
    )

    @file = Rack::Test::UploadedFile.new(
      File.join(Rails.root, 'spec', 'support', 'hrms.jpg')
    )

    @attachment = create(:attachment,file: @file, employee_id: @hr_employee.id)
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  describe '$Attachments' do
    let(:response_json) {JSON.parse(response.body)}

    before(:each) do
      login_as_user(@hr_employee.id)
    end

    context 'save attachments of performance' do
      it "should create attachment success" do
        post :create, format: :json, performance_id: @hr_performance.id,\
          id: @attachment.id
        expect(response).to be_success
        expect(response_json["attachments"].size).to be > 0
      end
    end

    context 'show attachments list of performances' do
      it "show performances attachments" do
        @attachment.attachmentable = @hr_performance
        @attachment.save
        put :show, format: :json, performance_id: @hr_performance.id
        expect(response_json["attachments"].size).to be > 0
      end
    end

    context 'destroy attachments of performances' do
      it 'should delete performances attachments success' do
        @attachment.attachmentable = @hr_performance
        @attachment.save

        delete :destroy, format: :json, performance_id: @hr_performance.id,\
          id: @attachment.id
        expect(response).to be_success
      end

      it "shouldn't delete performances other people upload attachments" do
        @attachment = create(:attachment,file: @file,employee_id: @employee.id)
        @attachment.attachmentable = @employee_performance
        @attachment.save

        delete :destroy, format: :json, performance_id: @hr_performance.id,\
          id: @attachment.id
        expect(response.status).to eq(400)
      end
    end
  end
end
