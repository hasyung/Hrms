require "rails_helper"

RSpec.describe FutureTask, type: :model do
  describe "perform generate_season_performance" do
    before(:each) do
      dep_grade = create(:department_grade)
      dep_nature = create(:department_nature)
      dep = create(:root_department, grade_id: dep_grade.id, nature_id: dep_nature.id)

      pos_cat = create(:master_pos_category)
      pos_channel = create(:channel)
      pos = create(:position, department_id: dep.id, category_id: pos_cat.id, channel_id: pos_channel.id)

      category_id = CodeTable::Category.create(display_name: '干部').id
      emp_1 = create(:employee, name: '汪良平', employee_no: '000882', department_id: dep.id, category_id: category_id, pcategory: '主官')

      EmployeePosition.create(employee_id: emp_1.id, position_id: pos.id)
    end

    context "perform date is unmatched" do
      it "should not perform" do
        FutureTask.generate_season_performance

        expect(Performance.count).to eq(0)
      end
    end
  end
end