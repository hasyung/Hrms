require 'rails_helper'

RSpec.describe Api::PerformanceAllegesController, :type => :controller do
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

    # 构造岗位数据
    @pos_cat = create(:master_pos_category)
    @pos_channel = create(:channel)
    @basic_pos = create(:position, department_id: @second_dep.id, category_id: @pos_cat.id, channel_id: @pos_channel.id)

    # 构建员工数据
    @employment_status = create(:employment_status)
    @employee = create(:employee, department_id: @second_dep.id, gender_id: create(:gender_male).id)
    EmployeePosition.create(employee_id: @employee.id, position_id: @basic_pos.id)

    @file = Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'support', 'hrms.jpg'))

    @performance = create(:performance, employee_id: @employee.id)
    @manager_perfor = create(:manager_perfor, employee_id: @employee.id)

    login_as_user(@employee.id)
  end

  after(:each) do
    puts JSON.pretty_generate(json)
  end

  describe 'performance_alleges#create' do
    context "with rightful params" do
      it "should create performance_alleges success" do

        post :create, format: :json, performance_id: @performance.id,
          reason: '我的家在哪？'
        expect(response).to be_success
        expect(json["allege"]["reason"]).to eq('我的家在哪？')
        expect(json["allege"]["performance_id"]).to eq(@performance.id)
      end
    end
  end

  describe 'performance_alleges#attachment_create' do
    context "with rightful params" do
      it "should create performance_allege_attachment success" do
        @performance_allege = create(:performance_allege, performance_id: @performance.id,
          outcome: '通过', reason: '我想要一个家')

        post :attachment_create, format: :json, id: @performance_allege.id, file: @file
        expect(response).to be_success
      end
    end
  end

  describe 'performance_alleges#attachment_destroy' do
    context "with rightful params" do
      it "should destroy performance_allege_attachment success" do
        @performance_allege = create(:performance_allege, performance_id: @performance.id,
          outcome: '通过', reason: '我想要一个家')
        @attachment = create(:performance_allege_attachment, performance_allege_id: @performance_allege.id,
          file: @file, employee_id: @employee.id)

        delete :attachment_destroy, format: :json, id: @performance_allege.id, attachment_id: @attachment.id
        expect(response).to be_success
        expect(json["messages"]).to eq('附件删除成功')
      end
    end
  end

  describe 'performance_alleges#index' do
    context "with rightful params" do
      it "should get performance_alleges list" do
        @performance_allege = create(:performance_allege, performance_id: @performance.id,
          outcome: '通过', reason: '我想要一个家')
        @manager_allege = create(:performance_allege, performance_id: @manager_perfor.id,
          outcome: '不通过', reason: '你娃要死嗖')

        get :index, format: :json
        expect(response).to be_success
        expect(json["alleges"].size).to eq(2)
      end
    end
  end
end
