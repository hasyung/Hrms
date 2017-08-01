require 'rails_helper'

RSpec.describe Api::LeaveEmployeesController, type: :controller do
  render_views

  before(:each) do
    @leave_employee = create(:leave_employee)
    @zhang = create(:zhang)

    @hr_labor_relation_member = create(:hr_labor_relation_member, department_id: @root_department)
    login_as_user(@hr_labor_relation_member.id)
  end

  describe "#index" do

    let(:json) {JSON.parse(response.body)}

    context "without search conditions" do
      it "should list todos" do
        get :index, format: :json
        expect(response).to be_success
        expect(json["leave_employees"].size).to eq(2)
        puts JSON.pretty_generate(json)
      end
    end

    context "with page conditions" do 
      it "should list todos" do 
        get :index, format: :json, page: 2, per_page:1
        expect(response).to be_success
        expect(json["leave_employees"].size).to eq(1)
        puts JSON.pretty_generate(json)
      end
    end

    context "with search conditions: " do 
      it "should list todos" do 
        get :index, format: :json, name: '张', change_date: {"from" => "2001-05-13", "to" => "2015-05-13"}
        expect(response).to be_success
        expect(json["leave_employees"].size).to eq(1)
        puts JSON.pretty_generate(json)
      end
    end
  end

  describe "#export_to_xls" do
    context "without search conditions" do
      it "should send file" do
        get :export_to_xls, format: :json
        expect(response).to be_success
        expect(response.content_type).to eq("application/octet-stream")
      end
    end
  end

end
