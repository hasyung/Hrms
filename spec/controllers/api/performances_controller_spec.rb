require 'rails_helper'

RSpec.describe Api::PerformancesController, type: :controller do
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

    10.times do |index|
      @employee = create(
        :employee,
        department_id: @other_second_dep.id,
        pcategory: ["员工","基层干部","中层干部","主官"][index % 4]
      )

      EmployeePosition.create(
        employee_id: @employee.id,
        position_id: @other_basic_pos.id
      )

      create(
        :performance,
        result: ['优秀','良好','合格','待改进','不合格','无'][index % 6],
        assess_time: Date.today().to_s,
        category: ["year","season","month"][index % 3],
        employee_name: @employee.name,
        employee_id: @employee.id,
        employee_no: @employee.employee_no
      )
    end

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
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  describe '$index' do
    let(:response_json) {JSON.parse(response.body)}

    context 'login as hr' do
      before(:each) do
        login_as_user(@hr_employee.id)
      end

      after(:each) do
        puts JSON.pretty_generate(response_json)
      end

      it "should list all employee's performances by hr" do
        get :index, format: :json
        expect(response_json['performances'].size).to eq(11)
      end

      it 'should list by condition result' do
        result = ['优秀','良好','合格','待改进','不合格','无'].sample
        get :index, format: :json, result: result
        expect(response_json['performances'][0]["result"]).to eq(result)
      end

      it 'should list page 2 performances' do
        get :index, format: :json, page: 2, per_page: 5
        expect(response_json['meta']['pages_count']).to eq(3)
        expect(response_json['performances'].size).to eq(5)
      end
    end

    context 'login as department_hr' do
      before(:each) do
        login_as_user(@employee.id)
      end

      it 'should list this department_hr has permission to see performances' do
        get :index, format: :json
        expect(response_json['performances'].size).to eq(10)
      end
    end

    context 'login as normal employee' do
      before(:each) do
        # 构建其他一级部门
        @other_dep_grade = create(:department_grade)
        @other_dep_nature = create(:department_nature)
        @other_dep = create(:root_department, grade_id: @other_dep_grade.id, nature_id: @other_dep_nature.id, serial_number: '000050')
        @employee = create(:employee, department_id: @other_dep.id)

        create(:performance,
               result: ['优秀', '良好', '合格', '待改进', '不合格', '无'].sample,
               assess_time: ['2015', '201501', '2015Q1'].sample,
               employee_name: @employee.name,
               employee_id: @employee.id,
               employee_no: @employee.employee_no
              )

        login_as_user(@employee.id)
      end

      it 'should only list self performances' do
        get :index, format: :json
        expect(response_json['performances'].size).to eq(1)
      end

      it "should cound't load other employee's performances when just normal employee" do
        get :index, format: :json, employee_name: @hr_employee.name
        expect(response_json['performances'].size).to eq(1)
      end
    end
  end

  describe "$temps" do
    let(:response_json) {JSON.parse(response.body)}
    before(:each) do
      login_as_user(@hr_employee.id)
    end

    context "list the employee's performances temp" do
      it "should list performances temp success" do
        get :temp, format: :json
        expect(response_json["temps"].size).to be >= 1
      end

      it "should list performances temp with conditions" do
        get :temp, format: :json, pcategory: '主官'
        expect(response_json["temps"].size).to be >= 1
      end
    end

    context "update the employee's performances temp" do
      it "should update the month_distribute_base success" do
        post :update_temp, format: :json, id: @employee.id, month_distribute_base: 99999.99
        @employee.reload
        expect(response_json["messages"]).to eq("修改成功")
        expect(@employee.month_distribute_base).to eq(BigDecimal.new("99999.99"))
      end

      it "should update the employee pcategory success" do
        post :update_temp, format: :json, id: @employee.id, pcategory: '主官'
        @employee.reload
        expect(response_json["messages"]).to eq("修改成功")
        expect(@employee.pcategory).to eq("主官")
      end

      it "should update the employee month_distribute_base or pcategory" do
        post :update_temp, format: :json, id: @employee.id, pcategory: '主官', name: "Ray"
        @employee.reload
        expect(response_json["messages"]).to eq("修改成功")
        expect(@employee.name).not_to eq("Ray")
      end
    end

    context "hr temp_export" do
      it "should export_to_xls success" do
        login_as_user(@hr_employee.id)
        get :temp_export, format: :json
        expect(response).to be_success
        expect(response.content_type).to eq("application/octet-stream")
      end
    end

    context "department_hr temp_export" do
      it "should export_to_xls success" do
        login_as_user(@employee.id)
        get :temp_export, format: :json
        expect(response).to be_success
        expect(response.content_type).to eq("application/octet-stream")
      end
    end
  end
end
