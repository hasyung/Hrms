require 'rails_helper'

RSpec.describe Api::ContractsController, type: :controller do
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

    @employee = create(:employee, department_id: @second_dep.id, gender_id: create(:gender_male).id)
    EmployeePosition.create(employee_id: @employee.id, position_id: @basic_pos.id)

    @hr_labor_relation_member = create(:hr_labor_relation_member, department_id: @root_department)

    @contract = create(:contract, employee_id: @employee.id)
    @contract_l = create(:contract_l)
    @contract_h = create(:contract_h)
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  before(:each) do
    login_as_user(@hr_labor_relation_member.id)
  end

  describe '#create' do
    let(:response_json) {JSON.parse(response.body)}

    context 'create no due_time contract' do
      it 'should create contract success' do
        post :create, format: :json, employee_id: @employee.id,
          apply_type: '合同工', change_flag: '新签',
          start_date: Date.today.to_s, statsu: '在职',
          notes: 'just a test'
        expect(response).to be_success
        expect(response_json["contract"]["end_date"]).to eq(nil)
      end

      it 'should create contract success' do
        post :create, format: :json, employee_id: @employee.id,
          apply_type: '合同工', change_flag: '新签',
          start_date: Date.today.to_s, due_time: '1',
          end_date: Date.tomorrow.to_s, statsu: '在职',
          notes: 'just a test'
        #puts JSON.pretty_generate(response_json)
        expect(response).to be_success
        expect(Date.parse(response_json["contract"]["end_date"])).to eq(Date.tomorrow)
      end
    end

    context 'create new contract when old contracts end_data' do
      it "should create new contract when old contract pass end_date" do
        post :create, format: :json, employee_id: @employee.id,
          apply_type: '合同工',change_flag: '续签',
          start_date: Date.today.to_s, due_time: '10',
          end_date: Date.tomorrow.to_s, statsu: '在职',
          notes: 'just a test'
        expect(response).to be_success
        expect(Date.parse(response_json["contract"]["end_date"])).to eq(Date.tomorrow)
      end
    end
  end

  describe "#show" do
    let(:response_json) {JSON.parse(response.body)}

    context "show show the contract info" do
      it "should list contract info" do
        get :show, format: :json, id: @contract.id
        #puts JSON.pretty_generate(response_json)
        expect(response).to be_success
      end
    end

  end

  describe '#index' do
    let(:response_json) {JSON.parse(response.body)}

    context 'normal get contracts list' do
      it 'should list contracts success' do
        get :index, format: :json
        expect(response).to be_success
        expect(response_json['contracts'].size).to eq(3)
      end
    end

    context 'search conditions' do
      it 'should list specially employee_name contracts' do
        get :index, format: :json, employee_name: '何章林'
        expect(response).to be_success
        expect(response_json['contracts'].size).to eq(1)
      end

      it 'should list specially department_name contracts' do
        get :index, format: :json, department_name: '保卫处'
        expect(response).to be_success
        expect(response_json['contracts'].size).to eq(2)
      end

      it 'should list specially status contracts' do
        get :index, format: :json, status: '退休'
        expect(response).to be_success
        expect(response_json['contracts'].size).to eq(1)
      end

      it 'should list has notes contracts' do
        get :index, format: :json, notes: true
        expect(response).to be_success
        expect(response_json['contracts'].size).to eq(1)
      end

      it 'should list did not has notes contracts' do
        get :index, format: :json, notes: false
        expect(response).to be_success
        expect(response_json['contracts'].size).to eq(2)
      end

      it 'should list contracts with combination conditions' do
        get :index, format: :json, notes: true, department_name: '人力资源部'
        expect(response).to be_success
        expect(response_json['contracts'].size).to eq(1)
      end
    end

    context 'search page conditions' do
      it 'should list page 1 contracts' do
        get :index, format: :json, page: 1, per_page: 1
        expect(response).to be_success
        expect(response_json["meta"]["pages_count"]).to eq(3)
      end

      it 'should list page 2 contracts' do
        get :index, format: :json, page: 2, per_page: 1
        expect(response).to be_success
        expect(response_json["meta"]["pages_count"]).to eq(3)
        expect(response_json['contracts'].size).to eq(1)
      end
    end
  end
end
