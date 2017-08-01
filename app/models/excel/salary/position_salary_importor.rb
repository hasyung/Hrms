module Excel
  module Salary
    class PositionSalaryImportor
      BASIC_KEY_HASH = {
        "管理"  => 'manager15_base',
        "营销"  => 'manager15_base',
        "机务"  => 'manager15_base',
        "航务航材" => 'manager15_base',
        "空勤" => 'air_steward_base',
        "信息" => 'manager15_base',
        "服务C"  => 'service_c_base',
        "服务C-驾驶"  => 'service_c_driving_base',
        "飞行"  => 'air_observer_base',
        "服务B-清洁工" => 'service_b_normal_cleaner_base',
        "服务B-机坪清洁工" => 'service_b_parking_cleaner_base',
        "服务B-宾馆服务员" => 'service_b_hotel_service_base',
        "服务B-绿化" => 'service_b_green_base',
        "服务B-总台服务员" => 'service_b_front_desk_base',
        "服务B-保安、空保装备保管员" => 'service_b_security_guard_base',
        "服务B-数据录入" => 'service_b_input_base',
        "服务B-保安队长(一类)" => 'service_b_guard_leader1_base',
        "服务B-保管(库房、培训设备、器械)" => 'service_b_device_keeper_base',
        "服务B-外站装卸" => 'service_b_unloading_base',
        "服务B-制水工" => 'service_b_making_water_base',
        "服务B-加水工、排污工" => 'service_b_add_water_base',
        "服务B-保安队长(二类)" => 'service_b_guard_leader2_base',
        "服务B-水电维修" => 'service_b_water_light_base',
        "服务B-汽修工" => 'service_b_car_repair_base',
        "服务B-机务工装设备/客舱供应库管" => 'service_b_airline_keeper_base'
      }

      MANAGE_HASH = {
        "高级"  => 'A',
        "中级"  => 'B',
        "本科含以上"  => 'E',
        "大专" => 'F',
        "大专以下" => 'G'
      }

      def self.import(file_path)
        puts "准备导入员工的基本工资，如果员工存在，但是薪酬个人设置不存在会自动创建空的"
        array, count = [], 0

        sheet0 = get_book(file_path).worksheet(0)
        sheet1 = get_book(file_path).worksheet(1)
        global = ::Salary.find_by(category: 'global').form_data
        salaries_hash = ::Salary.where("category in (?)", BASIC_KEY_HASH.values.uniq | ['leader_base']).index_by(&:category)
        employees_hash = Employee.unscoped.includes(:salary_person_setup).index_by(&:employee_no)

        ActiveRecord::Base.transaction do
          puts "===== 员工 ====="
          sheet0.each_with_index do |row, index|
            next if index == 0 || row[0].blank?
            count += 1
            employee = employees_hash[row[0]]

            if employee.present? && row[13].present? && row[37].present?
              setup = employee.salary_person_setup || employee.build_salary_person_setup

              row[13] = '服务C' if row[13].to_s.include?('服务C') && !row[13].to_s.end_with?('驾驶')
              base_wage = BASIC_KEY_HASH[row[13]] || BASIC_KEY_HASH[row[13].to_s + '-' + row[6].to_s]
              base_flag  = salaries_hash[base_wage].get_flag_by_amount(row[37].to_i) if base_wage
              base_channel = nil
              if base_wage && base_wage == 'manager15_base'
                base_channel = MANAGE_HASH[row[9]] || MANAGE_HASH[row[8]]
              elsif base_wage
                base_channel = salaries_hash[base_wage].form_data["flag_names"].select{|k, v| %w(X 默认).include?(v)}.keys.first
              end

              if base_wage.blank? || base_channel.blank? || base_flag.blank?
                array << "#{index + 1} #{row[0]} #{row[1]}"
              else
                if row[13] == '服务B'
                  setup.update(
                    base_wage: base_wage,
                    base_flag: base_flag,
                    base_channel: base_channel,
                    base_performance_money: row[37].to_f,
                    base_money: global["minimum_wage"],
                    performance_money: row[37].to_f - global["minimum_wage"]
                  )
                else
                  setup.update(
                    base_wage: base_wage,
                    base_flag: base_flag,
                    base_channel: base_channel,
                    base_money: row[37].to_f
                  )
                end
              end
            else
              array << "#{index + 1} #{row[0]} #{row[1]}"
            end
          end

          puts "===== 干部 ====="
          sheet1.each_with_index do |row, index|
            next if index == 0 || row[0].blank?
            count += 1
            employee = employees_hash[row[0]]

            if employee.present? && row[11].present? && row[43].present?
              setup = employee.salary_person_setup || employee.build_salary_person_setup
              base_wage = 'leader_base'

              # case row[12]
              # when '飞行'
              #   base_wage = 'air_observer_base'
              # when '空勤'
              #   base_wage = 'leader_base'
              # else
              #   base_wage = 'leader_base'
              # end

              base_channel  = row[11]
              base_flag  = salaries_hash[base_wage].get_flag_by_amount(row[43].to_i) if base_wage

              if base_channel.blank? || base_flag.blank?
                array << "#{index + 1} #{row[0]} #{row[1]}"
              else
                setup.update(
                  base_wage: base_wage,
                  base_flag: base_flag,
                  base_channel: base_channel,
                  base_money: row[43].to_f
                )
              end
            else
              array << "#{index + 1} #{row[0]} #{row[1]}"
            end
          end

          if array.size > 0
            puts array.join("\r\n").red
            puts "警告:有 #{array.size} 行导入失败，失败率 #{(array.size*100.0/count).round(2)}% \r\n\r\n".red
          end

        end
      end

      def self.get_book(file_path)
        Spreadsheet.open(file_path)
      end
    end
  end
end
