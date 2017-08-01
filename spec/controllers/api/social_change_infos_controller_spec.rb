require 'rails_helper'

RSpec.describe Api::SocialChangeInfosController, type: :controller do
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
    @hr_labor_relation_member = create(:hr_labor_relation_member, department_id: @second_dep.id)
    @hr_pos = create(:position, department_id: @root_dep.id, category_id: @pos_cat.id, channel_id: @pos_channel.id)
    EmployeePosition.create(employee_id: @hr_labor_relation_member.id, position_id: @hr_pos.id)

    @personage = create(:social_person_setup, employee_id: @employee.id)
    @log_first = create(:social_change_info, employee_id: @employee.id, salary_reason: '辞职', category: '停薪调')

    login_as_user(@hr_labor_relation_member.id)
  end

  describe "#index" do

    context "without search conditions" do
      it "should list todos" do
        @log_second = create(:social_change_info, employee_id: @hr_labor_relation_member.id)

        get :index, format: :json
        expect(response).to be_success
        expect(json["social_change_infos"].size).to eq(2)
        puts JSON.pretty_generate(json)
      end
    end

    context "with page conditions" do 
      it "should list todos" do 
        @log_second = create(:social_change_info, employee_id: @hr_labor_relation_member.id)

        get :index, format: :json, page: 2, per_page:1
        expect(response).to be_success
        expect(json["social_change_infos"].size).to eq(1)
        puts JSON.pretty_generate(json)
      end
    end
  end

  describe "#update" do
    context "when category == '合同新签'" do
      it "should update social_change_info success" do
        @log_second = create(:social_change_info, employee_id: @hr_labor_relation_member.id)

        patch :update, format: :json, id: @log_second.id, state: '处理完毕'
        expect(response).to be_success
        expect(@log_second.reload.state).to eq("处理完毕")
        puts JSON.pretty_generate(json)
      end
    end

    context "when category == '停薪调'" do
      it "should update social_change_info success" do
        @log = create(:log_first, employee_id: @hr_labor_relation_member.id, salary_reason: '辞职', category: '停薪调')

        patch :update, format: :json, id: @log.id, state: '停交社保'
        expect(response).to be_success
        expect(@log.reload.state).to eq("停交社保")
      end
    end
  end


  describe "#show" do
    context "with rightful params" do
      it "should get a social_person_setup success" do
        get :show, format: :json, id: @log_first.id
        expect(response).to be_success
        expect(json["social_change_info"]["id"]).to eq(@log_first.id)
        puts JSON.pretty_generate(json)
      end
    end
  end


end
