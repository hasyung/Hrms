require 'rails_helper'

RSpec.describe Allowance, type: :model do
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

    # 岗位高温补贴设置
    @pos.update(temperature_amount: 800)

    @salary_setup = SalaryPersonSetup.create({employee_id: @employee.id})

    @month = "2015-09"

    # 增加配置
    @temp_setting = {
      category: 'temp',
      table_type: 'static',
      form_data: {
        'city_list' => [
          {"start_month"=>6, "end_month"=>8, "cities"=>["北京", "天津"]},
          {"start_month"=>6, "end_month"=>9, "cities"=>["成都", "昆明", "贵阳"]},
          {"start_month"=>6, "end_month"=>10, "cities"=>["广州", "重庆"]},
          {"start_month"=>3, "end_month"=>11, "cities"=>["三亚", "海口"]}
        ]
      }
    }

    Salary.create(@temp_setting)

    @allowance_setting = {
      category: 'allowance',
      table_type: 'static',
      form_data: {"security_subsidy"=>{"lower"=>100, "middle"=>400, "higher"=>600}, "placement_subsidy"=>500, "leader_subsidy"=>{"line_A"=>100, "line_B"=>100, "line_C"=>100, "line_D"=>100, "logistics_1"=>100, "logistics_2"=>100}, "terminal_subsidy"=>{"first"=>100, "second"=>100}, "car_subsidy"=>500, "ground_subsidy"=>{"first"=>100, "second"=>100, "third"=>100, "fourth"=>100, "fifth"=>100, "sixth"=>100}, "machine_subsidy"=>{"first"=>100, "second"=>100, "third"=>100, "fourth"=>100, "fifth"=>100}, "trial_subsidy"=>{"first"=>100, "second"=>100}, "honor_subsidy"=>{"copper"=>100, "silver"=>100, "gold"=>100, "exploit"=>100}}
    }

    Salary.create(@allowance_setting)

    %w(管理 机务 营销 飞行 空勤 服务A 服务B 服务C-1 信息 服务C-2 服务C-3 服务C-驾驶 航务航材 服务C).each {|x|CodeTable::Channel.create(display_name: x)}
  end

  describe "Allowance#compute" do
    it "should sum of the project together" do
      @employee.update(location: '成都')
      @salary_setup.update({security_subsidy: "lower", leader_subsidy: "line_A", terminal_subsidy: "first", ground_subsidy: "first", machine_subsidy: "first", trial_subsidy: "first", honor_subsidy: "copper"})
      Allowance.compute(@month)
      puts CalcStep.first.step_notes
    end
  end

  describe "Allowance#calc_temperature" do
    it "should calc temperature fee for fly channel" do
      hash = {employee_id: @employee.id, category: 'allowance', month: @month}
      calc_step = CalcStep.find_or_initialize_by(hash)
      @employee.update(location: '成都')

      fly_channel_id = CodeTable::Channel.where(display_name: '飞行').first.id
      @employee.update({channel_id: fly_channel_id})

      # 个人高温补贴设置，即使有也按照 6-9 300 补贴执行
      @salary_setup.update(temp_allowance: 900)
      allow(@employee).to receive(:is_unfly?).and_return(false)
      expect(Allowance.calc_temperature(@employee, @month, calc_step)).to eq(300)
      puts calc_step.step_notes

      # 当月未飞
      puts "------------------"
      puts "设置飞行员当月不飞"
      calc_step.step_notes.clear
      allow(@employee).to receive("is_unfly?").with(@month).and_return(true)
      expect(Allowance.calc_temperature(@employee, @month, calc_step)).to eq(0)
      puts calc_step.step_notes
    end

    it "should calc temperature fee for no fly channel" do
      hash = {employee_id: @employee.id, category: 'allowance', month: @month}
      calc_step = CalcStep.find_or_initialize_by(hash)
      @employee.update(location: '成都')

      expect(Allowance.calc_temperature(@employee, @month, calc_step)).to eq(800)
      puts calc_step.step_notes
    end

    it "should calc temperature fee for special states" do
      hash = {employee_id: @employee.id, category: 'allowance', month: @month}
      calc_step = CalcStep.find_or_initialize_by(hash)
      @employee.update(location: '未知地点')

      # 设置派驻天数小于 15 天
      from = Date.parse(@month + "-20")
      to = Date.parse(@month + "-10").next_month
      hash = {employee_id: @employee.id, special_category: '派驻', special_location: '三亚', special_date_from: from, special_date_to: to}
      SpecialState.create(hash)

      expect(Allowance.calc_temperature(@employee, @month, calc_step)).to eq(400)
      puts calc_step.step_notes
    end
  end
end
