require 'spreadsheet'

module Excel
  module Salary
    class FlyerImportor
      FLYER_HOUR = {
        "教员1"        => "teacher_A",
        "教员2"        => "teacher_B",
        "责任机长1"    => "leader_A",
        "责任机长2"    => "leader_B",
        "机长"         => "leader",
        "副驾驶特别档" => "copilot_special",
        "副驾驶1"      => "copilot_1",
        "副驾驶2"      => "copilot_2",
        "副驾驶3"      => "copilot_3",
        "副驾驶4"      => "copilot_4",
        "副驾驶5"      => "copilot_5",
        "副驾驶6"      => "copilot_6",
        "飞行学员"   => "student",
        "空中机械员"   => "observer"
      }

      FLYER_SUBSIDY = {
        "教员1"        => "teacher",
        "教员2"        => "teacher",
        "责任机长1"    => "duty_leader",
        "责任机长2"    => "duty_leader",
        "机长"         => "leader",
        "副驾驶特别档" => "copilot_special",
        "副驾驶1"      => "copilot_1",
        "副驾驶2"      => "copilot_2",
        "副驾驶3"      => "copilot_3",
        "副驾驶4"      => "copilot_4",
        "副驾驶5"      => "copilot_5",
        "副驾驶6"      => "copilot_6",
        "飞行学员"     => "student"
      }

      FLY_ATTENDANT_HOUR = {
        "乘务长A"     => "purser_A",
        "乘务长B"     => "purser_B",
        "乘务长C"     => "purser_C",
        "乘务长D"     => "purser_D",
        "乘务长E"     => "purser_E",
        "头等舱A"     => "first_class_A",
        "头等舱B"     => "first_class_B",
        "乘务员A"     => "attendant_A",
        "乘务员B"     => "attendant_B",
        "乘务员C"     => "attendant_C",
        "见习乘A" => "trainee_A",
        "见习乘B" => "trainee_B"
      }

      AIR_SECURITY_HOUR = {
        "资深安A" => "security_A",
        "资深安B" => "security_B",
        "资深安C" => "security_C",
        "资深安D" => "security_D",
        "安全员A" => "safety_A",
        "安全员B" => "safety_B",
        "安全员C" => "safety_C",
        "安全员D" => "safety_D",
        "见习安"  => "noviciate_safety"
      }

      def self.import(file_path, is_import = false)
        file_path = "#{Rails.root}/public/#{file_path}" if is_import
        book   = get_book(file_path)
        sheet1 = book.worksheet 0
        sheet2 = book.worksheet 1
        sheet3 = book.worksheet 2

        flyer_hour         = ::Salary.find_by(category: 'flyer_hour').form_data
        fly_attendant_hour = ::Salary.find_by(category: 'fly_attendant_hour').form_data
        air_security_hour  = ::Salary.find_by(category: 'air_security_hour').form_data
        market_leader_perf = ::Salary.find_by(category: 'market_leader_perf').form_data
        flyer_science_subsidy = ::Salary.find_by(category: 'flyer_science_subsidy').form_data
        employees_hash = Employee.unscoped.includes(:salary_person_setup).index_by(&:employee_no)

        error_names, error_count = [], 0

        puts "$$$ 开始导入员工的小时费档级设置，如果员工存在，但是薪酬个人设置不存在会自动创建空的"

        SalaryPersonSetup.transaction do
          puts "飞行员"
          sheet1.each_with_index do |row, index|
            next if index == 0 || row[2].blank?
            employee = employees_hash[row[0]]

            if employee.blank? || FLYER_HOUR[row[2]].blank?
              row[1] += "  " if row[1].to_s.length == 2
              puts "#{index + 1} #{row[0]} #{row[1]}"
              error_names << row[1]
              error_count += 1
            else
              setup = employee.salary_person_setup || employee.build_salary_person_setup
              setup.fly_hour_fee = FLYER_HOUR[row[2]]
              setup.fly_hour_money = flyer_hour[FLYER_HOUR[row[2]]]
              if row[4].present?
                setup.leader_grade = row[4]
                flag = market_leader_perf["flags"].select{|k,v| v['X']['format_cell'] == row[4]}
                setup.performance_money = flag.map{|k, v| v["amount"]}.first unless flag.blank?
              end

              if FLYER_SUBSIDY[row[2]]
                setup.is_send_flyer_science = true
                setup.flyer_science_subsidy = FLYER_SUBSIDY[row[2]]
                setup.flyer_science_money = flyer_science_subsidy[setup.flyer_science_subsidy]
              end
              setup.save
            end
          end

          puts "乘务员"
          sheet2.each_with_index do |row, index|
            next if index == 0 || row[2].blank?
            employee = employees_hash[row[0]]

            if employee.blank? || FLY_ATTENDANT_HOUR[row[2]].blank?
              row[1] += "  " if row[1].to_s.length == 2
              puts "#{index + 1} #{row[0]} #{row[1]}"
              error_names << row[1]
              error_count += 1
            else
              setup = employee.salary_person_setup || employee.build_salary_person_setup
              setup.airline_hour_fee = FLY_ATTENDANT_HOUR[row[2]]
              setup.airline_hour_money = fly_attendant_hour[FLY_ATTENDANT_HOUR[row[2]]]
              if row[4].present?
                setup.leader_grade = row[4]
                flag = market_leader_perf["flags"].select{|k,v| v['X']['format_cell'] == row[4]}
                setup.performance_money = flag.map{|k, v| v["amount"]}.first unless flag.blank?
              end
              setup.save
            end
          end

          puts "安全员"
          sheet3.each_with_index do |row, index|
            next if index == 0 || row[2].blank?
            employee = employees_hash[row[0]]

            if employee.blank? || AIR_SECURITY_HOUR[row[2]].blank?
              row[0] += "  " if row[0].to_s.length == 2
              puts "#{index + 1} #{row[0]} #{row[1]}"
              error_names << row[1]
              error_count += 1
            else
              setup = employee.salary_person_setup || employee.build_salary_person_setup
              setup.security_hour_fee = AIR_SECURITY_HOUR[row[2]]
              setup.security_hour_money = air_security_hour[AIR_SECURITY_HOUR[row[2]]]
              if row[3].present?
                setup.airline_hour_fee = FLY_ATTENDANT_HOUR[row[3]]
                setup.airline_hour_money = fly_attendant_hour[FLY_ATTENDANT_HOUR[row[3]]]
              end
              if row[5].present?
                setup.leader_grade = row[5]
                flag = market_leader_perf["flags"].select{|k,v| v['X']['format_cell'] == row[5]}
                setup.performance_money = flag.map{|k, v| v["amount"]}.first unless flag.blank?
              end
              setup.save
            end
          end
        end

        count = sheet1.count + sheet2.count + sheet3.count - 3

        if error_count > 0
          puts "提示: 总共处理 #{count} 行数据".yellow
          puts "警告: 有 #{error_count} 行导入失败，失败率 #{error_count * 100/count}% \r\n\r\n".red
        end

        {
          success_count: count - error_count,
          error_count: error_count,
          error_names: error_names
        }
      end

      private
      def self.get_book(file_path)
        Spreadsheet.open(file_path)
      end
    end
  end
end
