require 'rails_helper'

RSpec.describe LandAllowance, type: :model do
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

    %w(管理 机务 营销 飞行 空勤 服务A 服务B 服务C-1 信息 服务C-2 服务C-3 服务C-驾驶 航务航材 服务C).each {|x|CodeTable::Channel.create(display_name: x)}

    @salary_setup = SalaryPersonSetup.create({employee_id: @employee.id})
    @month = "2015-09"

    @setting = {
      category: "global",
      table_type: "static",
      form_data: {
        "dollar_rate"=>6.3643,
        "minimum_wage"=>1200,
        "average_wage"=>2400,
        "basic_cardinality"=>1400,
        "perf_award_cardinality"=>100,
        "coefficient"=>{
          "2015-06"=>{"company"=>500, "business_council"=>400, "logistics"=>300},
          "2015-07"=>{"company"=>500, "business_council"=>400, "logistics"=>300},
          "2015-09"=>{"company"=>0.1, "business_council"=>0.1, "logistics"=>0.1, "perf_check"=>100, "perf_execute"=>100},
          "2015-10"=>{"company"=>0.1, "business_council"=>0.1, "logistics"=>0.1, "perf_check"=>1, "perf_execute"=>1}
        },
        "flight_bonus"=>{"2015"=>{"sent"=>0, "budget"=>101}},
        "service_bonus"=>{"2015"=>{"sent"=>0, "budget"=>102}},
        "ailine_security_bonus"=>{"2015"=>{"sent"=>0, "budget"=>103}},
        "composite_bonus"=>{"2015"=>{"sent"=>0, "budget"=>104}}
      }
    }
    Salary.create(@setting)

    @setting = {
      category: 'land_subsidy',
      table_type: 'static',
      form_data: {"general"=>{"amount"=>100, "cities"=>nil}, "highland_1st"=>{"amount"=>120, "cities"=>["拉萨", "九黄"]}, "highland_2nd"=>{"amount"=>135, "cities"=>["康定", "稻城", "你好"]}, "high_cold"=>{"amount"=>60, "cities"=>["乌鲁木齐", "哈尔滨"]}, "overseas_1st"=>{"amount"=>80, "cities"=>["首尔", "温哥华", "墨尔本", "悉尼", "大阪", "东京", "迪拜", "莫斯科"]}, "overseas_2nd"=>{"amount"=>70, "cities"=>["普吉", "香港", "台湾"]}, "overseas_3rd"=>{"amount"=>60, "cities"=>["河内", "胡志明", "加德满都"]}}
    }
    Salary.create(@setting)

    @setting = {
      category: 'airline_subsidy',
      table_type: 'static',
      form_data: {"inland_areas"=>[{"city"=>"北京", "abbr"=>"京"}, {"city"=>"石家庄", "abbr"=>"石"}, {"city"=>"南宁", "abbr"=>"邕"}, {"city"=>"海口", "abbr"=>"琼"}, {"city"=>"三亚", "abbr"=>"三"}], "outland_areas"=>[{"city"=>"温哥华", "abbr"=>"温", "outland_subsidy"=>50}, {"city"=>"塞班", "abbr"=>"塞", "outland_subsidy"=>50}, {"city"=>"莫斯科", "abbr"=>"谢", "outland_subsidy"=>50}, {"city"=>"墨尔本", "abbr"=>"墨", "outland_subsidy"=>50}, {"city"=>"阿尔及利亚", "abbr"=>"及利亚", "outland_subsidy"=>20}], "inland_subsidy"=>{"airline"=>{"general"=>180, "metaphase"=>6500, "long_term"=>8000}, "cabin"=>{"general"=>100, "metaphase"=>3500, "long_term"=>4000}, "air_security"=>{"general"=>100, "metaphase"=>3500, "long_term"=>4000}}, "outland_subsidy"=>50}
    }
    Salary.create(@setting)
  end

  describe "LandAllowance#compute" do
    it "should sum of the project together" do
      LandAllowance.compute(@month)
      expect(LandAllowance.first.total).to eq(0)
      puts CalcStep.first.step_notes
    end

    it "should sum of items for no fly&airline_service channel" do
      @employee.update({location: '成都'})

      from = Date.parse(@month + "-10").prev_month
      to = Date.parse(@month + "-10")
      hash = {employee_id: @employee.id, special_category: '派驻', special_location: '乌鲁木齐', special_date_from: from, special_date_to: to}
      SpecialState.create(hash)

      LandAllowance.compute(@month)
      puts CalcStep.first.step_notes
    end

    it "should sum of items for no fly&airline_service channel" do
      fly_channel_id = CodeTable::Channel.where(display_name: '飞行').first.id
      @employee.update({channel_id: fly_channel_id, location: '成都'})

      # 设置 本月08-本月15 为FOC表导入记录
      hash = {employee_name: @employee.name, days: 5, start_day: 2, end_day: 6, month: @month, city: '乌鲁木齐'}
      LandRecord.create(hash)

      # 境外
      hash = {employee_name: @employee.name, days: 8, start_day: 8, end_day: 15, month: @month, city: '塞班'}
      LandRecord.create(hash)

      # 设置 本月10-下月15 是中长期期派驻
      from = Date.parse(@month + "-12")
      to = Date.parse(@month + "-25").next_month.next_month
      hash = {employee_id: @employee.id, special_date_from: from, special_date_to: to, special_location: '温哥华', special_category: '派驻'}
      SpecialState.create(hash)

      allow(Employee).to receive('get_vacation_dates').with(@month).and_return([Date.parse(@month + "-20"), Date.parse(@month + "-22")])

      LandAllowance.compute(@month)
      puts CalcStep.first.step_notes
    end
  end
end
