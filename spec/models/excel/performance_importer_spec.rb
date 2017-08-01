require "rails_helper"

RSpec.describe Excel::PerformanceImporter, type: :model do
  before(:each) do
    dep_grade = create(:department_grade)
    dep_nature = create(:department_nature)
    dep = create(:root_department, grade_id: dep_grade.id, nature_id: dep_nature.id)

    pos_cat = create(:master_pos_category)
    pos_channel = create(:channel)
    pos = create(:position, department_id: dep.id, category_id: pos_cat.id, channel_id: pos_channel.id)

    category_id = CodeTable::Category.create(display_name: '干部').id
    emp_1 = create(:employee, name: '汪良平', employee_no: '000882', department_id: dep.id, category_id: category_id)
    emp_2 = create(:employee, name: '张爱云', employee_no: '000225', department_id: dep.id, category_id: category_id)

    EmployeePosition.create(employee_id: emp_1.id, position_id: pos.id)
    EmployeePosition.create(employee_id: emp_2.id, position_id: pos.id)
  end

  describe "import annual performance check data" do
    context "manager performance check data" do
      context "with valid data" do
        before(:each) do
          date = Date.today.end_of_year
          performance_importer = Excel::PerformanceImporter.new("#{Rails.root}/spec/support/valid_manager_annual_performance_check.xlsx", date, 'year').call
          @messages = performance_importer.messages
        end

        it "should success" do
          expect(@messages[:errors].count).to eq(0)
        end

        it "should be sorted" do
          expect(Performance.first.sort_no.to_i).to eq(1)
          expect(Performance.last.sort_no.to_i).to eq(2)
        end
      end
    end

    context "employee performance check data" do
      before(:each) do
        date = Date.today.end_of_year
        performance_importer = Excel::PerformanceImporter.new("#{Rails.root}/spec/support/valid_employee_annual_performance_check.xlsx", date, 'year').call
        @messages = performance_importer.messages
      end

      context "with valid data" do
        it "should success, but not be sorted" do
          expect(Performance.first.sort_no).to eq(nil)
          expect(Performance.first.result).to eq("优秀")
        end
      end
    end
  end

  describe "import month performance check data" do
    context "with valid data" do
      it "should success" do
        date = Date.today.beginning_of_month
        performance_importer = Excel::PerformanceImporter.new("#{Rails.root}/spec/support/valid_employee_month_performance_check.xlsx", date, 'month').call
        messages = performance_importer.messages
        performance = Performance.first

        expect(messages[:fail_count]).to eq(0)
        expect(performance.department_distribute_result).to eq(5000)
        expect(performance.month_distribute_base).to eq(7500)
        expect(performance.department_reserved).to eq(6000)
      end
    end
  end
end
