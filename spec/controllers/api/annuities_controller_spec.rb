require 'rails_helper'

RSpec.describe Api::AnnuitiesController, type: :controller do
  render_views
  before(:all) do
    DatabaseCleaner.start
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

    @employee = create(
      :employee,
      department_id: @second_dep.id,
      gender_id: create(:gender_male).id,
      pcategory: ["员工","基层干部","中层干部","主官"].sample,
      annuity_cardinality: rand() * 100000,
      annuity_account_no: '400800123321',
      annuity_status: false
    )

    EmployeePosition.create(employee_id: @employee.id, position_id: @basic_pos.id)

    @hr_labor_relation_member = create(
      :hr_labor_relation_member,
      department_id: @root_department,
      annuity_status: false
    )

    @relation = Employee::LaborRelation.create(display_name: '合同制')

    10.times do |index|
      @employee = create(
        :employee,
        department_id: @second_dep.id,
        annuity_status: [true, false][index%2],
        annuity_cardinality: 10000,
        annuity_account_no: "40080012332#{index}",
      )
      @employee.labor_relation = @relation
      @employee.save

      EmployeePosition.create(
        employee_id: @employee.id,
        position_id: @basic_pos.id
      )
    end

  end

  after(:all) do
    DatabaseCleaner.clean
  end

  describe "#index" do
    let(:response_json) {JSON.parse(response.body)}
    before(:each) do
      login_as_user(@hr_labor_relation_member.id)
    end

    context 'should list annuit list success' do
      it 'should get the index list' do
        get :index, format: :json
        expect(response).to be_success
        expect(response_json["annuities"].size).to eq(10)
      end
    end

    context 'should list annuit list success with condition' do
      it 'condition name' do
        get :index, format: :json, name: @employee.name
        expect(response).to be_success
        expect(response_json["annuities"].size).to be >= 1
      end

      it 'condition employee_no' do
        get :index, format: :json, employee_no: @employee.employee_no
        expect(response).to be_success
        expect(response_json["annuities"].size).to be >= 1
      end

      it 'condition annuity_status' do
        get :index, format: :json, annuity_status: false
        expect(response).to be_success
        expect(response_json["annuities"].size).to be >= 1
      end

      it 'condition page params' do
        get :index, format: :json, page: 2, per_page: 3
        expect(response).to be_success
        expect(response_json["meta"]["pages_count"]).to eq(4)
      end
    end
  end

  describe "#update" do
    let(:response_json) {JSON.parse(response.body)}
    before(:each) do
      login_as_user(@hr_labor_relation_member.id)
    end

    context "update annuity_cardinality" do
      it 'should update annuity_cardinality success' do
        patch :update, format: :json, annuity_cardinality: 99.99, id: @employee.id
        expect(response_json["messages"]).to eq("修改成功")
        @employee.reload
        expect(@employee.annuity_cardinality).to eq(BigDecimal.new("99.99"))
      end

      it "should update annuity_status success" do
        patch :update, format: :json, annuity_status: "在缴", id: @employee.id
        expect(response_json["messages"]).to eq("修改成功")
        @employee.reload
        expect(@employee.annuity_status).to eq(true)
      end

      it "shouldn't update other attrs" do
        patch :update, format: :json, id: @employee.id, name: "xxx"
        @employee.reload
        expect(@employee.name).not_to eq("xxx")
      end
    end
  end

  describe "#show personal_cardinality" do
    let(:response_json) {JSON.parse(response.body)}

    before(:each) do
      login_as_user(@hr_labor_relation_member.id)
    end

    it "should show personal_cardinality cal source" do
      last_year = Date.today.last_year.year
      12.times do |index|
        time = index < 9 ? "#{last_year}-0#{index+1}" : "#{last_year}-#{index+1}"
        @employee.social_records.create(
          compute_month: time,
          pension_cardinality: rand(20000)
        )
      end

      get :show_cardinality, format: :json, employee_id: @employee.id
      #puts JSON.pretty_generate(response_json)
      expect(response).to be_success
      expect(response_json["social_records"].size).to eq(12)

    end
  end

  describe "#cal cardinality" do
    before(:each) do
      login_as_user(@hr_labor_relation_member.id)
    end

    context 'cal_annuity' do
      it "should cal_annuity of offer date" do
        get :cal_annuity, format: :json, date: "2015-06"

        expect(response).to be_success
        #puts JSON.pretty_generate(JSON.parse(response.body))
        expect(Annuity.all.count).to be > 1
      end
    end

    context 'cal_year_annuity_cardinality' do
      it "should cal_year_annuity_cardinality success" do

        last_year = Date.today.last_year.year
        12.times do |index|
          time = index < 10 ? "#{last_year}-0#{index}" : "#{last_year}-#{index}"
          @employee.social_records.create(
            compute_month: time,
            pension_cardinality: 20000
          )
        end

        get :cal_year_annuity_cardinality, format: :json
        expect(response).to be_success
        @employee.reload
        expect(@employee.annuity_cardinality).to eq(BigDecimal("20000"))
      end
    end
  end

  describe "#export" do
    context 'export all annuity' do
      it "should export_to_xls success" do
        login_as_user(@hr_labor_relation_member.id)

        get :export_to_xls, format: :json
        expect(response).to be_success
        expect(response.content_type).to eq("application/octet-stream")
      end
    end
  end
end
