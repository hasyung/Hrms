require 'rails_helper'

RSpec.describe RewardRecord, type: :model do
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

    @salary_setup = SalaryPersonSetup.create({employee_id: @employee.id})

    @month = "2015-09"
    condition = {employee_name: @employee.name, employee_no: @employee.employee_no, month: @month}
    @employee_record = RewardRecord.new(condition)

    @total_money = 0
    %w(flight_bonus service_bonus airline_security_bonus composite_bonus insurance_proxy cabin_grow_up full_sale_promotion article_fee all_right_fly year_composite_bonus move_perfect security_special dep_security_undertake fly_star year_all_right_fly network_connect quarter_fee earnings_fee off_budget_fee).each do |field|
      @employee_record.update({field.to_sym => 0.99})
      @total_money += 0.99
    end
  end

  describe "Reward#compute" do
    context "with right condition" do
      it "should sum of the project together" do
        Reward.compute(@month)
        expect(Reward.count).to eq(1)
        expect(Reward.first.total).to eq(@total_money)
        puts CalcStep.all.map(&:step_notes)
      end
    end
  end
end
