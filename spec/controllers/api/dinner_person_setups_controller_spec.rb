require 'rails_helper'

RSpec.describe Api::DinnerPersonSetupsController, type: :controller do
  render_views

  let(:json) {JSON.parse(response.body)}

  before(:each) do
    # 构建一级部门
    @root_dep_grade = create(:department_grade)
    @root_dep_nature = create(:department_nature)
    @root_dep = create(:root_department,
                       grade_id: @root_dep_grade.id,
                       nature_id: @root_dep_nature.id)

    # 构建二级部门
    @second_dep_grade = create(:positive_grade)
    @second_dep_nature = create(:department_nature)
    @second_dep = create(:second_department, parent_id: @root_dep.id, grade_id: @second_dep_grade.id)

    # 构造岗位数据
    @pos_cat = create(:master_pos_category)
    @pos_channel = create(:channel)
    @basic_pos = create(:position, department_id: @second_dep.id, category_id: @pos_cat.id, channel_id: @pos_channel.id)

    # 构建员工数据
    @employment_status = create(:employment_status)
    @employee = create(:employee, department_id: @second_dep.id, gender_id: create(:gender_male).id)
    EmployeePosition.create(employee_id: @employee.id, position_id: @basic_pos.id)

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
    begin
      # 可能是发送文件
      puts JSON.pretty_generate(json)
    rescue => ex
      puts ex
    end
  end

  describe "with action" do
    it "should list" do
      @employee.update(location: '成都')
      create(:dinner_person_setup, employee_id: @employee.id, employee_no: @employee.employee_no, change_date: Time.new.to_date)

      login_as_user(@employee.id)
      get :index, format: :json
      expect(response).to be_success
    end

    it "should show" do
      @employee.update(location: '成都')
      @setup = create(:dinner_person_setup, employee_id: @employee.id, employee_no: @employee.employee_no, change_date: Time.new.to_date)

      login_as_user(@employee.id)
      get :show, format: :json, id: @setup.id
      expect(response).to be_success
    end

    it "should update" do
      @employee.update(location: '成都')
      @setup = create(:dinner_person_setup, employee_id: @employee.id, employee_no: @employee.employee_no, change_date: Time.new.to_date)

      login_as_user(@employee.id)

      # 从 "行政班" 变到 "两班倒"
      patch :update, format: :json, id: @setup.id, working_fee: 99, card_amount: 100, shifts_type: '两班倒'
      expect(response).to be_success
      expect(DinnerPersonSetup.first.working_fee).to eq(99)
    end

    it "should load config with meal area" do
      login_as_user(@employee.id)

      get :load_config, form_data: :json, shifts_type: "行政班", area: "机关食堂"
      expect(response).to be_success
    end

    it "should load config with cash area" do
      login_as_user(@employee.id)

      get :load_config, form_data: :json, shifts_type: "行政班", area: "上海"
      expect(response).to be_success
    end
  end
end
