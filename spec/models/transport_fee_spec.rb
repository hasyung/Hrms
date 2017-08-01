require 'rails_helper'

RSpec.describe TransportFee, type: :model do
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

    %w(公司正职 公司副职 总师/总监 总助职 一正 二正 二副级 一副 二副 一副级 分公司级).each {|x|Employee::DutyRank.create(display_name: x)}

    %w(管理 机务 营销 飞行 空勤 服务A 服务B 服务C-1 信息 服务C-2 服务C-3 服务C-驾驶 航务航材 服务C).each {|x|CodeTable::Channel.create(display_name: x)}

    %w(领导 干部 员工).each {|x|CodeTable::Category.create(display_name: x)}

    @salary_setup = SalaryPersonSetup.create({employee_id: @employee.id})
    @month = "2015-09"
  end

  describe "TransportFee#compute" do
    context "with stop salary status" do
      it "should be zero" do
        @employee.update({is_stop_salary: true})
        TransportFee.compute(@month)
        expect(TransportFee.first.total).to eq(0)
        puts CalcStep.all.map(&:step_notes)
      end
    end

    context "not fly & airline_service channel" do
      it "should sum of the project together" do
        TransportFee.compute(@month)
        expect(TransportFee.first.total).to eq(600)
        puts CalcStep.all.map(&:step_notes)
      end

      it "should deduct bus fee" do
        TransportFee.compute(@month)
        expect(TransportFee.first.total).to eq(600)
        puts CalcStep.all.map(&:step_notes)
      end
    end

    context "with fly channel" do
      it "should sum of the project together" do
        fly_channel_id = CodeTable::Channel.where(display_name: '飞行').first.id
        @employee.update({channel_id: fly_channel_id})

        TransportFee.compute(@month)
        expect(TransportFee.first.total).to eq(1200)
        puts CalcStep.all.map(&:step_notes)
      end

      it "should be zero if rank great than assistant" do
        fly_channel_id = CodeTable::Channel.where(display_name: '飞行').first.id
        duty_rank_id = Employee::DutyRank.where(display_name: '总助职').first.id
        @employee.update({channel_id: fly_channel_id, duty_rank_id: duty_rank_id})

        TransportFee.compute(@month)
        expect(TransportFee.first.total).to eq(0)
        puts CalcStep.all.map(&:step_notes)
      end

      it "should adjustment of right duty rank" do
        fly_channel_id = CodeTable::Channel.where(display_name: '飞行').first.id
        duty_rank_id = Employee::DutyRank.where(display_name: '一副级').first.id
        @employee.update({channel_id: fly_channel_id, duty_rank_id: duty_rank_id})

        TransportFee.compute(@month)
        expect(TransportFee.first.total).to eq(1200)
        puts CalcStep.all.map(&:step_notes)
      end

      it "should adjustment of fly student" do
        fly_channel_id = CodeTable::Channel.where(display_name: '飞行').first.id
        @employee.update({channel_id: fly_channel_id})
        @salary_setup.update({base_channel: 'flyer_student_base'})

        TransportFee.compute(@month)
        expect(TransportFee.first.total).to eq(600)
        puts CalcStep.all.map(&:step_notes)
      end

      it "should adjustment of leaving fly student" do
        fly_channel_id = CodeTable::Channel.where(display_name: '飞行').first.id
        @employee.update({channel_id: fly_channel_id})
        @employee.update({leave_flyer_student_date: Date.parse(@month + '-01')})

        TransportFee.compute(@month)
        expect(TransportFee.first.total).to eq(600)
        puts CalcStep.all.map(&:step_notes)

        @employee.update({leave_flyer_student_date: Date.parse(@month + '-01').prev_month.beginning_of_month})
        TransportFee.compute(@month)
        expect(TransportFee.first.total).to eq(1200)
        puts CalcStep.all.map(&:step_notes)

        @employee.update({leave_flyer_student_date: Date.parse(@month + '-10')})
        TransportFee.compute(@month)
        expect(TransportFee.first.total).to eq(600)
        puts CalcStep.all.map(&:step_notes)
      end
    end

    context "with airline_service channel" do
      it "should sum of the project together" do
        fly_channel_id = CodeTable::Channel.where(display_name: '空勤').first.id
        @employee.update({channel_id: fly_channel_id})

        TransportFee.compute(@month)
        expect(TransportFee.first.total).to eq(1100)
        puts CalcStep.all.map(&:step_notes)
      end

      it "should adjustment of thec leader category" do
        fly_channel_id = CodeTable::Channel.where(display_name: '空勤').first.id
        category_id = CodeTable::Category.where(display_name: '干部').first.id
        @employee.update({channel_id: fly_channel_id, category_id: category_id})

        TransportFee.compute(@month)
        expect(TransportFee.first.total).to eq(600)
        puts CalcStep.all.map(&:step_notes)
      end

      it "should adjustment of land worker" do
        fly_channel_id = CodeTable::Channel.where(display_name: '空勤').first.id
        @employee.update({channel_id: fly_channel_id})

        # 无结束时间
        @state = SpecialState.create({employee_id: @employee.id, special_date_from: Date.parse(@month + "-01").prev_month.beginning_of_month, special_category: '空勤地面'})

        TransportFee.compute(@month)
        expect(TransportFee.first.total).to eq(600)
        puts CalcStep.all.map(&:step_notes)

        # 有结束时间
        @state.update({special_date_to: Date.parse(@month + "-01").prev_month.end_of_month})

        TransportFee.compute(@month)
        expect(TransportFee.first.total).to eq(600)
        puts CalcStep.all.map(&:step_notes)
      end
    end
  end
end
