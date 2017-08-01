require 'rails_helper'

RSpec.describe LeaveEmployee, type: :model do
  before :each do
    # 构建一级部门
    @dep_grade = create(:department_grade)
    @dep_nature = create(:department_nature)
    @dep = create(:root_department, grade_id: @dep_grade.id, nature_id: @dep_nature.id)

    # 构造岗位数据
    @pos_cat = create(:master_pos_category)
    @pos_channel = create(:channel)
    @pos = create(:position, department_id: @dep.id, category_id: @pos_cat.id, channel_id: @pos_channel.id)

    @employee = create(:employee, department_id: @dep.id)
    EmployeePosition.create(employee_id: @employee.id, position_id: @pos.id)

    @hr_labor_relation_member = create(:hr_labor_relation_member)
  end

  describe "class method#create_by_employee" do
    context "employee with full infos" do
      it "should return leave_employee" do
        @leave_employee = LeaveEmployee.create_by_employee(@employee, '111111')
        expect(@leave_employee.class).to eq(LeaveEmployee)
        expect(@leave_employee.name).to eq(@employee.name)
        puts @leave_employee.try(:attributes)
      end
    end

    context "employee without full infos" do
      it "should return nil" do
        @leave_employee = LeaveEmployee.create_by_employee(@hr_labor_relation_member, '222222')
        expect(@leave_employee).to eq(nil)
      end
    end
  end

  describe "Subscriber&Publisher#EMPLOYEE_LEAVE" do
    context "with full infos" do
      it "employee should be leave" do
        hash = {employee_id: @employee.id, file_no: '111', reason: '辞职', date: '2000-01-01'}
        Publisher.broadcast_event('EMPLOYEE_LEAVE', hash)
        @employee = @employee.reload
        expect(@employee.is_delete).to eq(true)
        expect(@employee.employee_positions).to eq([])
        expect(@employee.approve_leave_job_date.to_s).to eq(hash[:date])
        expect(@employee.leave_job_reason).to eq(hash[:reason])

        @leave_employee = LeaveEmployee.find_by(name: @employee.name, employee_no: @employee.employee_no)
        expect(@leave_employee.class).to eq(LeaveEmployee)
        puts @leave_employee.try(:attributes)
      end
    end
  end

end
