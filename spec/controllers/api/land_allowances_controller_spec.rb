require 'rails_helper'

RSpec.describe Api::LandAllowancesController, type: :controller do
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
    @month = "2015-11"

    @salary = Salary.new(category: 'land_subsidy')
    @form_data = {
      "general" => {
        "amount" => 100,
        "cities" => []
      },
      "highland_1st" => {
        "amount" => 120,
        "cities" => [
          "拉萨",
          "九黄"
        ]
      },
      "highland_2nd" => {
        "amount" => 135,
        "cities" => [
          "康定",
          "稻城"
        ]
      },
      "high_cold" => {
        "amount" => 60,
        "cities" => [
          "乌鲁木齐",
          "哈尔滨"
        ]
      },
      "overseas_1st" => {
        "amount" => 80,
        "cities" => [
          "首尔",
          "温哥华",
          "墨尔本",
          "悉尼",
          "大阪",
          "东京",
          "迪拜",
          "莫斯科"
        ]
      },
      "overseas_2nd" => {
        "amount" => 70,
        "cities" => [
          "普吉",
          "香港",
          "台湾"
        ]
      },
      "overseas_3rd" => {
        "amount" => 60,
        "cities" => [
          "河内",
          "胡志明",
          "加德满都"
        ]
      }
    }

    @salary.save

    @salary = Salary.new(category: 'global')
    @form_data = {
      "dollar_rate" => 6.12345,
      "minimum_wage" => 1201,
      "average_wage" => 2400,
      "basic_cardinality" => 1400,
      "coefficient" => {
        "2015-06" => {
          "company" => 500,
          "business_council" => 400,
          "logistics" => 300
        },
        "2015-07" => {
          "company" => 500,
          "business_council" => 400,
          "logistics" => 300
        },
        "2015-10" => {
          "company" => 0.1,
          "business_council" => 0.1,
          "logistics" => 0.1
        }
      },
      "perf_award_cardinality" => 1212
    }

    @salary.form_data = @form_data
    @salary.save

    @salary = Salary.new(category: 'airline_subsidy')
    @form_data = {
      "inland_areas" => [
        {
          "city" => "北京",
          "abbr" => "京"
        },
        {
          "city" => "石家庄",
          "abbr" => "石"
        },
        {
          "city" => "南宁",
          "abbr" => "邕"
        },
        {
          "city" => "海口",
          "abbr" => "琼"
        },
        {
          "city" => "三亚",
          "abbr" => "三"
        },
        {
          "city" => "昆明",
          "abbr" => "昆"
        }
      ],
      "outland_areas" => [
        {
          "city" => "温哥华",
          "abbr" => "温"
        },
        {
          "city" => "塞班",
          "abbr" => "塞"
        },
        {
          "city" => "莫斯科",
          "abbr" => "谢"
        },
        {
          "city" => "墨尔本",
          "abbr" => "墨"
        },
        {
          "city" => "悉尼",
          "abbr" => "悉"
        }
      ],
      "inland_subsidy" => {
        "airline" => {
          "general" => 180,
          "metaphase" => 6500,
          "long_term" => 8000
        },
        "cabin" => {
          "general" => 100,
          "metaphase" => 3500,
          "long_term" => 4000
        },
        "air_security" => {
          "general" => 100,
          "metaphase" => 3500,
          "long_term" => 4000
        }
      },
      "outland_subsidy" => 50
    }

    @salary.form_data = @form_data
    @salary.save

    @salary_person_setup = SalaryPersonSetup.create(employee_id: @employee.id)
  end

  after(:each) do
    puts JSON.pretty_generate(json)
  end

  describe "with action" do
    it "should compute" do
      login_as_user(@employee.id)

      allow(SalaryPersonSetup).to receive(:check_compute).and_return(nil)
      allow(AttendanceSummary).to receive(:can_calc_salary?).and_return([true, ""])
      get :compute, format: :json, month: @month
      expect(response).to be_success
      puts response.body

      get :index, format: :json
      expect(response).to be_success
    end
  end
end
