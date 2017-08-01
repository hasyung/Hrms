require 'rails_helper'

RSpec.describe Api::AttachmentsController, type: :controller do
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

    @file = Rack::Test::UploadedFile.new(
      File.join(Rails.root, 'spec', 'support', 'hrms.jpg')
    )
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  describe "UPLOAD_ATTACHMENTS" do
    let(:response_json) {JSON.parse(response.body)}
    before(:each) do
      login_as_user(@employee.id)
    end

    context 'update file no file type check' do
      it 'should upload file success' do
        post :upload_file, file: @file
        expect(response).to be_success
        expect(response_json["employee_id"]).to eq(@employee.id)
      end
    end
  end
end
