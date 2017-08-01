require "rails_helper"

RSpec.describe Excel::MonthDistributeBaseImporter, type: :model do 
  before(:each) do
    create(:employee, name: '汪良平', employee_no: '000882')
    create(:employee, name: '张爱云', employee_no: '000225')
  end

  describe "import valid data" do 
    it "should success" do 
      month_base_importer = Excel::MonthDistributeBaseImporter.new("#{Rails.root}/spec/support/employee_valid_month_base.xlsx").call
      messages = month_base_importer.messages

      expect(messages[:errors].count).to eq(0)
    end
  end

  describe "import invalid data" do 
    it "should fail" do 
      month_base_importer = Excel::MonthDistributeBaseImporter.new("#{Rails.root}/spec/support/employee_invalid_month_base.xlsx").call
      messages = month_base_importer.messages

      expect(messages[:fail_count]).to eq(2)
      expect(messages[:errors]).to eq(['张爱云: 考核结果必须为数字类型; ', "沈诚: 人员沈诚不存在; "])
    end
  end
end
