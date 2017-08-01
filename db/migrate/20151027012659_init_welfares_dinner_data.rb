class InitWelfaresDinnerData < ActiveRecord::Migration
  def change
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
          {"areas" => "北头食堂", "shifts_type" => "四班倒", "charge_amount" => 140, "breakfast_number" => 8, "breakfast_card_amount" => 3, "breakfast_subsidy_amount" => 2, "lunch_number" => 8, "lunch_card_amount" => 8, "lunch_subsidy_amount" => 11, "dinner_number" => 8, "dinner_card_amount" => 6, "dinner_subsidy_amount" => 7},
          {"areas" => "北头食堂", "shifts_type" => "空勤干部", "charge_amount" => 140, "breakfast_number" => 8, "breakfast_card_amount" => 3, "breakfast_subsidy_amount" => 2, "lunch_number" => 8, "lunch_card_amount" => 8, "lunch_subsidy_amount" => 1, "dinner_number" => 8, "dinner_card_amount" => 6, "dinner_subsidy_amount" => 7},
          {"areas" => "北头食堂", "shifts_type" => "空勤人员", "charge_amount" => 150, "breakfast_number" => 0, "breakfast_card_amount" => 3, "breakfast_subsidy_amount" => 0, "lunch_number" => 23, "lunch_card_amount" => 8, "lunch_subsidy_amount" => 11, "dinner_number" => 10, "dinner_card_amount" => 6, "dinner_subsidy_amount" => 7}
        ]
      },
      {
        "others" =>
        [
          {"cities" => ['拉萨'], amount: 43},
          {"cities" => ['北京','上海','广州','深圳','杭州','三亚','宁波','温州','厦门','九黄指挥中心'], amount: 38},
          {"cities" => ['济南','郑州','长春','大连','乌鲁木齐','西宁','南宁','银川','海口','绵阳','福州','贵阳','哈尔滨','南昌','南京','天津','西安','长沙','桂林','呼和浩特','攀枝花','西昌','沈阳','武汉'], amount: 27},
          {"cities" => ['昆明食堂', '重庆食堂'], amount: 20},
          {"cities" => ['成都市区'], amount: 13},
          {"cities" => ['宜宾'], amount: 100},
          {"cities" => ['中卫'], amount: 120},
          {"cities" => ['康定', '稻城'], amount: 45},
          {"cities" => ['长水机场'], amount: 30},
          {"cities" => ['西安派驻'], amount: 60},
          {"cities" => ['哈尔滨派驻'], amount: 90}
        ]
      }
    ]

    Welfare.create(category: 'dinners', form_data: form_data)
  end
end
