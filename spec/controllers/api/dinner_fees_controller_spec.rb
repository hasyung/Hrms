require 'rails_helper'

RSpec.describe Api::DinnerFeesController, type: :controller do
  render_views

  let(:json) {JSON.parse(response.body)}

  before(:each) do
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

    @setup = DinnerPersonSetup.create({employee_id: @employee.id, employee_no: @employee.employee_no, employee_name: @employee.name, card_amount: 200, breakfast_number: 7, lunch_number: 11, dinner_number: 7, working_fee: 0, shifts_type: '行政班', area: '机关食堂'})
    @month = "2015-11"

    form_data = [
      {
        "chengdu_head_office" =>
        [
          {"areas" => "机关食堂", "shifts_type" => "行政班", "charge_amount" => 150, "breakfast_number" => 0, "breakfast_card_amount" => 4, "breakfast_subsidy_amount" => 0, "lunch_number" => 23, "lunch_card_amount" => 7, "lunch_subsidy_amount" => 11, "dinner_number" => 0, "dinner_card_amount" => 0, "dinner_subsidy_amount" => 0},
          {"areas" => "机关食堂", "shifts_type" => "两班倒", "charge_amount" => 260, "breakfast_number" => 0, "breakfast_card_amount" => 4, "breakfast_subsidy_amount" => 0, "lunch_number" => 16, "lunch_card_amount" => 7, "lunch_subsidy_amount" => 11, "dinner_number" => 0, "dinner_card_amount" => 0, "dinner_subsidy_amount" => 0},
          {"areas" => "机关食堂", "shifts_type" => "三班倒", "charge_amount" => 180, "breakfast_number" => 0, "breakfast_card_amount" => 4, "breakfast_subsidy_amount" => 0, "lunch_number" => 11, "lunch_card_amount" => 7, "lunch_subsidy_amount" => 11, "dinner_number" => 0, "dinner_card_amount" => 0, "dinner_subsidy_amount" => 0},
          {"areas" => "空勤食堂", "shifts_type" => "空勤干部", "charge_amount" => 150, "breakfast_number" => 0, "breakfast_card_amount" => 0, "breakfast_subsidy_amount" => 0, "lunch_number" => 23, "lunch_card_amount" => 7, "lunch_subsidy_amount" => 20, "dinner_number" => 10, "dinner_card_amount" => 6, "dinner_subsidy_amount" => 16},
          {"areas" => "空勤食堂", "shifts_type" => "空勤人员", "charge_amount" => 50, "breakfast_number" => 0, "breakfast_card_amount" => 0, "breakfast_subsidy_amount" => 0, "lunch_number" => 10, "lunch_card_amount" => 7, "lunch_subsidy_amount" => 20, "dinner_number" => 10, "dinner_card_amount" => 6, "dinner_subsidy_amount" => 16}
        ]
      },
      {
        "chengdu_north_part" =>
        [
          {"areas" => "北头食堂", "shifts_type" => "行政班", "charge_amount" => 170, "breakfast_number" => 0, "breakfast_card_amount" => 4, "breakfast_subsidy_amount" => 0, "lunch_number" => 23, "lunch_card_amount" => 8, "lunch_subsidy_amount" => 11, "dinner_number" => 0, "dinner_card_amount" => 13, "dinner_subsidy_amount" => 0},
          {"areas" => "北头食堂", "shifts_type" => "两班倒", "charge_amount" => 260, "breakfast_number" => 0, "breakfast_card_amount" => 4, "breakfast_subsidy_amount" => 0, "lunch_number" => 16, "lunch_card_amount" => 8, "lunch_subsidy_amount" => 11, "dinner_number" => 0, "dinner_card_amount" => 13, "dinner_subsidy_amount" => 0},
          {"areas" => "北头食堂", "shifts_type" => "三班倒", "charge_amount" => 180, "breakfast_number" => 11, "breakfast_card_amount" => 3, "breakfast_subsidy_amount" => 2, "lunch_number" => 11, "lunch_card_amount" => 8, "lunch_subsidy_amount" => 11, "dinner_number" => 11, "dinner_card_amount" => 6, "dinner_subsidy_amount" => 7},
          {"areas" => "北头食堂", "shifts_type" => "空勤干部", "charge_amount" => 140, "breakfast_number" => 8, "breakfast_card_amount" => 3, "breakfast_subsidy_amount" => 2, "lunch_number" => 8, "lunch_card_amount" => 8, "lunch_subsidy_amount" => 1, "dinner_number" => 8, "dinner_card_amount" => 6, "dinner_subsidy_amount" => 7},
          {"areas" => "北头食堂", "shifts_type" => "空勤人员", "charge_amount" => 150, "breakfast_number" => 0, "breakfast_card_amount" => 3, "breakfast_subsidy_amount" => 0, "lunch_number" => 23, "lunch_card_amount" => 8, "lunch_subsidy_amount" => 11, "dinner_number" => 10, "dinner_card_amount" => 6, "dinner_subsidy_amount" => 7}
        ]
      },
      {
        "others" =>
        [
          {"cities" => ['拉萨'], amount: 1300, unit: 'month'},
          {"cities" => ['北京','上海','广州','深圳','杭州','三亚','宁波','温州','厦门','九黄指挥中心'], amount: 1150, unit: 'month'},
          {"cities" => ['济南','郑州','长春','大连','乌鲁木齐','西宁','南宁','银川','海口','绵阳','福州','贵阳','哈尔滨','南昌','南京','天津','西安','长沙','桂林','呼和浩特','攀枝花','西昌','沈阳','武汉'], amount: 800, unit: 'month'},
          {"cities" => ['昆明食堂', '重庆食堂'], amount: 600, unit: 'month'},
          {"cities" => ['成都市区'], amount: 400, unit: 'month'},
          {"cities" => ['长水机场'], amount: 700, unit: 'month'},
          {"cities" => ['西安基地派驻'], amount: 60, unit: 'day'},
          {"cities" => ['哈尔滨基地派驻'], amount: 90, unit: 'day'}
        ]
      }
    ]

    Welfare.create(category: 'dinners', form_data: form_data)
  end

  after(:each) do
    puts JSON.pretty_generate(json)
  end

  describe "with action" do
    it "should index" do
      @employee.update(location: '成都')
      login_as_user(@employee.id)
      create(:dinner_fee, employee_id: @employee.id, employee_no: @employee.employee_no, employee_name: @employee.name, month: @month)

      get :index, format: :json, month: @month
      expect(response).to be_success
    end

    it "should compute" do
      @employee.update(location: '成都')
      login_as_user(@employee.id)

      hash = {
        employee_id: @employee.id,
        special_date_from: Date.parse(@month + "-10").prev_month.prev_month,
        special_date_to: Date.parse(@month + "-20").prev_month,
        special_location: '拉萨',
        special_category: '派驻'
      }
      SpecialState.create(hash)

      get :compute, format: :json, month: @month, type: '工作餐'
      expect(response).to be_success
      puts CalcStep.first.step_notes
    end
  end
end
