class ClearFlyerHourHoursFeeGloabal < ActiveRecord::Migration
  def change
  	flyer_hour = {
      "teacher_A" => 420,            # 教员 A
      "teacher_B" => 400,            # 教员 B
      "leader_A" => 380,             # 责任机长 A
      "leader_B" => 360,             # 责任机长 B
      "leader" => 240,               # 机 长
      "copilot_special" => 240,      # 副驾驶特别档
      "copilot_1" => 190,            # 副驾驶 1
      "copilot_2" => 165,            # 副驾驶 2
      "copilot_3" => 155,            # 副驾驶 3
      "copilot_4" => 135,            # 副驾驶 4
      "copilot_5" => 130,            # 副驾驶 5
      "copilot_6" => 100,            # 副驾驶 6
      "observer" => 150,             # 空中观察员
      "student" => 0								 # 学员
    }

    flyer = Salary.find_or_create_by(category: 'flyer_hour', table_type: 'static')
    flyer.update(form_data: flyer_hour)
  end
end
