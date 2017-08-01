require 'rails_helper'

RSpec.describe Api::PositionsController, :type => :controller do
	render_views
	
	let(:json) {JSON.parse(response.body)}

	before(:each) do 
		# 构建一级部门
		@root_dep_grade = create(:department_grade)
		@root_dep_nature = create(:department_nature)
		@root_dep = create(:root_department, 
												grade_id: @root_dep_grade.id,
												nature_id: @root_dep_nature.id)

		# 构建二级部门
		@second_dep_grade = create(:positive_grade)
		@second_dep_nature = create(:department_nature)
		@second_dep = create(:second_department, parent_id: @root_dep.id, grade_id: @second_dep_grade.id)
		
		# 构造岗位数据
		@pos_cat = create(:master_pos_category)
		@pos_channel = create(:channel)
		@basic_pos = create(:position, department_id: @second_dep.id, category_id: @pos_cat.id, channel_id: @pos_channel.id)

		@schedule = create(:schedule)

		# 构建员工数据
		@employment_status = create(:employment_status)
		@employee = create(:employee, department_id: @second_dep.id, gender_id: create(:gender_male).id)
		EmployeePosition.create(employee_id: @employee.id, position_id: @basic_pos.id)
	end

	after(:each) do
		puts JSON.pretty_generate(json)
	end

	describe "positions" do 
		it "should list positions under department" do 
			login_as_user(@employee.id)

			get :index, format: :json, department_id: @second_dep.id
			expect(response).to be_success
		end

		it "should create position" do 
			login_as_user(@employee.id)

			post :create, format: :json, name: Faker::Name.name, 
									budgeted_staffing: 20, 
									channel_id: @pos_channel.id, 
									oa_file_no: "oa_1234", 
									schedule_id: @schedule.id,
									department_id: @second_dep.id,
									category_id: @pos_cat.id,
									position_nature_id: @second_dep_nature.id
			expect(response).to be_success
		end
	end
end
