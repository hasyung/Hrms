require 'rails_helper'

RSpec.describe Api::AnnuityApplyController, type: :controller do
  render_views

  before(:all) do
    DatabaseCleaner.start

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

    @employee = create(
      :employee,
      department_id: @other_second_dep.id,
      pcategory: ["员工","基层干部","中层干部","主官"].sample,
      annuity_cardinality: rand() * 10000,
      annuity_account_no: '400800123321',
    )

    EmployeePosition.create(
      employee_id: @employee.id,
      position_id: @other_basic_pos.id
    )

    @relation = Employee::LaborRelation.create(display_name: '合同制')
    @employee.labor_relation = @relation
    @employee.save

    10.times do |index|
      @emp = create(
        :employee,
        department_id: @other_second_dep.id,
        annuity_status: true
      )
      @emp.labor_relation = @relation
      @emp.save

      EmployeePosition.create(
        employee_id: @emp.id,
        position_id: @other_basic_pos.id
      )
      @emp.annuity_applies.create(
        employee_name:     @emp.name,
        employee_no:       @emp.employee_no,
        department_name:   "重要的测试部门",
        apply_category:    "申请退出",
        status:            false
      )
    end

  end

  after(:all) do
    DatabaseCleaner.clean
  end

  describe "AnnuityApply controller" do
    let(:response_json) {JSON.parse(response.body)}

    before(:each) do
      login_as_user(@employee.id)
    end

    context "apply_for_annuity" do
      it "should quit annuitiy plan" do
        get :apply_for_annuity, format: :json, status: false
        expect(AnnuityApply.all.count).to eq(11)
      end

      it "should join annuitiy plan" do
        @other_employee = create(
          :employee,  department_id: @other_second_dep.id,
          pcategory: ["员工","基层干部","中层干部","主官"].sample,
          annuity_cardinality: rand() * 10000,
          annuity_account_no: '400800123321',
          annuity_status: false
        )
        @other_employee.labor_relation = @relation
        @other_employee.save

        login_as_user(@other_employee.id)
        get :apply_for_annuity, format: :json, status: true
        expect(AnnuityApply.all.count).to eq(11)
      end
    end

    context "index list" do
      it "should list annuity_apply without condition" do
        get :index, format: :json
        expect(response_json["annuity_applies"].size).to eq(10)
      end

      it "should list annuity_applies with employee_name condition" do
        get :index, format: :json, employee_name: @emp.name
        expect(response_json["annuity_applies"].size).to be >= 1
      end

      it "should list annuity_applies with employee_no condition" do
        get :index, format: :json, employee_no: @emp.employee_no
        expect(response_json["annuity_applies"].size).to eq(1)
      end

      it "should list annuity_applies with page condition" do
        get :index, format: :json, page: 2, per_page: 3
        expect(response_json["meta"]["pages_count"]).to eq(4)
      end
    end

    context "handle_apply" do
      it "should handle_apply success" do
        get :handle_apply, format: :json, id: @emp.annuity_applies.first.id, handle_status: "退出"
        @emp.reload
        expect(@emp.annuity_status).to eq(false)
      end
    end
  end
end
