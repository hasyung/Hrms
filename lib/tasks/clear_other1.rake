namespace :clear do

  task temperature_amount: :environment do
    form_data = {
      "city_list" => [
        {
          "start_month" => 6,
          "end_month" => 8,
          "cities" => ["北京", "天津"]
        },
        {
          "start_month" => 6,
          "end_month" => 9,
          "cities" => ["成都", "昆明", "贵阳"]
        },
        {
          "start_month" => 6,
          "end_month" => 10,
          "cities" => ["广州", "重庆"]
        },
        {
          "start_month" => 3,
          "end_month" => 11,
          "cities" => ["三亚", "海口"]
        }
      ]
    }

    Salary.create(category: 'temp', table_type: 'static', form_data: form_data)
  end

end