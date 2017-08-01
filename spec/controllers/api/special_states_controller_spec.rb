require 'rails_helper'

RSpec.describe Api::SpecialStatesController, type: :controller do
  render_views
  before(:all) do
    DatabaseCleaner.start
    # 构建一级部门
    @root_dep_grade = create(:department_grade)
    @root_dep_nature = create(:department_nature)
    @root_dep = create(:root_department, name: "人力资源部", grade_id: @root_dep_grade.id, nature_id: @root_dep_nature.id)

    # 构建二级部门
    @second_dep_grade = create(:positive_grade)
    @second_dep = create(:second_department, parent_id: @root_dep.id, grade_id: @second_dep_grade.id)

    # 构建其他一级部门
    @other_root_dep_grade = create(:department_grade)
    @other_root_dep_nature = create(:department_nature)
    @other_root_dep = create(:root_department, grade_id: @other_root_dep_grade.id, nature_id: @other_root_dep_nature.id, serial_number: "9800980")

    # 构造岗位数据
    @pos_cat = create(:master_pos_category)
    @pos_channel = create(:channel)
    @basic_pos = create(:position, department_id: @second_dep.id, category_id: @pos_cat.id, channel_id: @pos_channel.id)

    # 构造其他岗位数据
    @other_pos_cat = create(:master_pos_category)
    @other_pos_channel = create(:channel)
    @other_basic_pos = create(:position, department_id: @other_root_dep.id, category_id: @other_pos_cat.id, channel_id: @other_pos_channel.id)


    @hr_employee = create(:employee, department_id: @root_dep.id, gender_id: create(:gender_male).id)
    EmployeePosition.create(employee_id: @hr_employee.id, position_id: @basic_pos.id)

    @hr_labor_relation_member = create(:hr_labor_relation_member, department_id: @root_department)

    10.times do |index|
      @employee = create(
        :employee,
        department_id: @other_root_dep.id,
      )

     EmployeePosition.create(
        employee_id: @employee.id,
        position_id: @other_basic_pos.id
      )

      SpecialState.create(
        employee_id: @employee.id,
        department_id: @root_dep.id,
        out_company: false,
        special_category: ["借调", "驻派"].sample,
        special_location: ["商务", "飞行大队"].sample,
        special_date_from: Date.today - 1.days,
        special_date_to: Date.today + 100.days,
        file_no: "OANO_998998"
      )
    end
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  describe '#index' do
    let(:response_json) {JSON.parse(response.body)}

    context 'login as hr' do
      before(:each) do
        login_as_user(@hr_employee.id)
      end

      after(:each) do
        #puts JSON.pretty_generate(response_json)
      end

      it "should list the index without page condition" do
        get :index, format: :json
        expect(response).to be_success
        expect(response_json["meta"]["count"]).to eq(10)
      end

      it "should list the index with page condition" do
        get :index, format: :json, page: 1, per_page: 5
        expect(response_json["special_states"].size).to eq(5)
      end

      it "should list with the condition special_location" do
        get :index, format: :json, special_location: "商务"
        expect(response).to be_success
        expect(response_json["special_states"].first["special_location"]).to eq("商务")
      end

      it "should list with the condition special_states" do
        get :index, format: :json, special_category: "驻派"
        expect(response).to be_success
        expect(response_json["special_states"].first["special_category"]).to eq("驻派")
      end
    end

    context "login as normal person" do
      before(:each) do
        login_as_user(@employee.id)
      end

      after(:each) do
        #puts JSON.pretty_generate(response_json)
      end

      it "should list only one special_state" do
        get :index, format: :json
        expect(response).to be_success
        expect(response_json["meta"]["count"]).to eq(1)
      end
    end
  end

  describe '#show' do
    let(:response_json) {JSON.parse(response.body)}

    before(:each) do
      login_as_user(@hr_employee.id)
    end

    after(:each) do
      #puts JSON.pretty_generate(response_json)
    end

    context "should get the info of special_state" do
      it 'should get info success' do
        @date = SpecialState.create(employee_id: @employee.id, out_company: true, special_date_from: Date.today, special_date_to: Date.today, special_category: '离岗培训')
        get :show, format: :json, id: @date.id
        expect(response).to be_success
      end
    end

  end

  describe '#update' do
    let(:response_json) {JSON.parse(response.body)}

    before(:each) do
      login_as_user(@hr_employee.id)
    end

    after(:each) do
      #puts JSON.pretty_generate(response_json)
    end

    context "should update success" do
      it "should update special_state success" do
        @date = SpecialState.create(employee_id: @employee.id, out_company: true, special_date_from: Date.today, special_date_to: Date.today, special_category: '离岗培训')

        patch :update, id: @date.id, file_no: "xxx001", special_date_to: Date.today + 1.days
        @date.reload
        expect(@date.file_no).to eq("xxx001")
        expect(@date.special_date_to).to eq(Date.today + 1.days)
      end
    end

    context "should update failed" do
      it "should update failed when didn't pass limited params" do
         @date = SpecialState.create(employee_id: @employee.id, out_company: true, special_date_from: Date.today, special_date_to: Date.today, special_category: '离岗培训')

        patch :update, id: @date.id, special_category: "借调"
        @date.reload
        expect(@date.special_category).to eq("离岗培训")
      end

      it "should update failed when special_state blank" do
        patch :update, id: 10001
        expect(response.status).to eq(400)
      end
    end
  end

  describe '#temporarily_transfer' do
    let(:response_json) {JSON.parse(response.body)}

    before(:each) do
      login_as_user(@hr_employee.id)
    end

    after(:each) do
      #puts JSON.pretty_generate(response_json)
    end

    context 'temporarily_transfer success' do
      it "it should transfer employee in_company success" do
        post :temporarily_transfer, format: :json, employee_id: @employee.id, out_company: false, department_id: @root_dep.id, special_date_from: Date.today, special_date_to: Date.today + 100.days
        expect(response).to be_success
      end

      it "it should transfer employee out_company success" do
        post :temporarily_transfer, format: :json, employee_id: @employee.id, out_company: true, special_date_from: Date.today, special_date_to: Date.today + 100.days
        expect(response).to be_success
      end
    end

    context "temporarily_transfer failed" do
      it 'it should transfer employee failed when employee blank' do
        post :temporarily_transfer, format: :json, employee_id: 10000000, special_date_from: Date.today, special_date_to: Date.today + 100.days
        expect(response.status).to eq(400)
      end

      it "it should transfer employee failed when in_company=false but didn't pass department_id" do
        post :temporarily_transfer, format: :json, employee_id: @employee.id, out_company: false, special_date_from: Date.today, special_date_to: Date.today + 100.days
        expect(response.status).to eq(400)
      end
    end
  end

  describe '#temporarily_defend' do
    let(:response_json) {JSON.parse(response.body)}

    before(:each) do
      login_as_user(@hr_employee.id)
    end

    after(:each) do
      #puts JSON.pretty_generate(response_json)
    end

    context "defend employee success" do
      it "it should defend employee success in company" do
        post :temporarily_defend, format: :json, employee_id: @employee.id, special_location: "西安", out_company: false, special_date_from: Date.today, special_date_to: Date.today + 100.days
        expect(response).to be_success
        expect(response_json["special_state"]["special_location"]).to eq("西安")
      end

      it "it should defend employee out company" do
        post :temporarily_defend, format: :json, employee_id: @employee.id, out_company: true, special_date_from: Date.today, special_date_to: Date.today + 100.days
        expect(response).to be_success
        expect(response_json["special_state"]["special_location"]).to eq("公司外")
      end
    end

    context "defend employee failed" do
      it "should failed when employee blank?" do
        post :temporarily_defend, format: :json, employee_id: 10099001, special_location: "西安", out_company: false, special_date_from: Date.today, special_date_to: Date.today + 100.days
        expect(response.status).to eq(400)
      end

      it "should failed when didn't pass special_location in company defend" do
        post :temporarily_defend, format: :json, employee_id: @employee.id, out_company: false, special_date_from: Date.today
        expect(response.status).to eq(400)
      end
    end
  end

 describe '#temporarily_train' do
   let(:response_json) {JSON.parse(response.body)}

   before(:each) do
     login_as_user(@hr_employee.id)
   end

   after(:each) do
     #puts JSON.pretty_generate(response_json)
   end

   context "temporarily_train success" do
     it "should success temporarily_train" do
       post :temporarily_train, format: :json, employee_id: @employee.id, special_date_from: Date.today, special_date_to: Date.today + 100.days
       expect(response).to be_success
     end
   end

   context "temporarily_train failed" do
     it "should failed temporarily_train when employee blank" do
       post :temporarily_train, format: :json, employee_id: 10000, special_date_from: Date.today, special_date_to: Date.today + 100.days
       expect(response.status).to eq(400)
     end
   end
  end

 describe '#temporarily_stop_air_duty' do
   let(:response_json) {JSON.parse(response.body)}

   before(:each) do
     login_as_user(@hr_employee.id)
   end

   after(:each) do
     puts JSON.pretty_generate(response_json)
   end

   context 'temporarily_stop_air_duty success' do
     it 'should success temporarily_stop_air_duty' do
       post :temporarily_stop_air_duty, format: :json, employee_id: @employee.id, special_date_from: Date.today, special_category: "空勤停飞"
       expect(response).to be_success
     end
   end
 end
end
