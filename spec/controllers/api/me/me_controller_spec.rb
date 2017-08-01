require 'rails_helper'

RSpec.describe Api::Me::MeController, type: :controller do
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

    10.times do |index|
      create(
        :performance,
        result: ['优秀','良好','合格','待改进','不合格','无'][index % 6],
        category: ["year","season","month"][index % 3],
        employee_name: @employee.name,
        employee_id: @employee.id,
        employee_no: @employee.employee_no
      )

      cal_date = index+1 <= 9 ? "2014-0#{index+1}" : "2014-#{index+1}"
      @employee.annuities.create(
        cal_date: cal_date,
        employee_no: @employee.employee_no,
        employee_name: @employee.name,
        employee_identity_name: @employee.identity_name,
        department_name: @employee.department.full_name,
        position_name: @employee.master_position.name,
        mobile: @employee.contact.mobile,
        identity_no: @employee.identity_no,
        annuity_account_no: @employee.annuity_account_no,
        annuity_cardinality: @employee.annuity_cardinality,
        company_payment: @employee.annuity_cardinality * 0.05,
        personal_payment: @employee.annuity_cardinality * 0.05
      )
    end

  end

  after(:all) do
    DatabaseCleaner.clean
  end

  describe "api/me me_controller" do
    let(:response_json) {JSON.parse(response.body)}

    before(:each) do
      login_as_user(@employee.id)
    end

    after(:each) do
      #puts JSON.pretty_generate(response_json)
    end

    context "employee get self performance" do
      it "get the performances list" do
        get :performances, format: :json
        expect(response_json["performances"].size).to eq(10)
      end
    end

    context "employee get self annuity records" do
      it "get the annuity list" do
        get :annuities, format: :json
        expect(response).to be_success
        puts JSON.pretty_generate(response_json)
      end
    end
  end
end
