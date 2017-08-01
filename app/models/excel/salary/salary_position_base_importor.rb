module Excel
  module Salary
    class SalaryPositionBaseImportor
      BASIC_KEY_HASH = {
        "副驾"  => 'flyer_copilot_base',
        "机长"  => 'flyer_leader_base',
        "责机"  => 'flyer_duty_leader_base',
        "教员A" => 'flyer_teacher_A_base',
        "教员B" => 'flyer_teacher_B_base',
        "教员C" => 'flyer_teacher_C_base',
        "荣誉"  => 'flyer_legend_base',
        "学员"  => 'flyer_student_base'
      }

      def self.import_flyer_position_base(file_path)
        puts "准备导入飞行员员工的基本工资，如果员工存在，但是薪酬个人设置不存在会自动创建空的"
        @array = []
        @count = 0

        @config = ::Salary.all.index_by(&:category)
        @sheet = get_sheet(file_path)
        @count = 0
        employees_hash = Employee.unscoped.includes(:salary_person_setup).index_by(&:employee_no)

        ActiveRecord::Base.transaction do
          @sheet.each_with_index do |row, index|
            next if row[0].to_s.include?('人员编号')
            next if row[0].blank? and row[1].blank?
            @count += 1
            @employee = employees_hash[row[0]]

            if @employee.present? && row[3].present?
              @setup = @employee.salary_person_setup || @employee.build_salary_person_setup
              base_flag     = row[3] != "机长" ? /([0-9]+)/.match(row[3].to_s)[0] : '1'
              base_wage_key = row[3] != "机长" ? /([0-9]+)/.match(row[3].to_s).pre_match : '机长'
              base_wage     = BASIC_KEY_HASH[base_wage_key]
              base_channel  = "X"

              if base_wage.blank? || base_flag.blank? || !@config[base_wage]['form_data']['flag_list'].include?(base_channel)
                @array << "#{index + 1} #{row[0].to_s} #{row[1].to_s} 配置 #{row[3]} 配置解析有误"
              else
                @setup.update(
                  base_wage: base_wage,
                  base_flag: base_flag,
                  base_channel: base_channel,
                  base_money: @config[base_wage]['form_data']['flags'][base_flag]['amount']
                )
              end
            else
              @array << "#{index + 1} #{row[0].to_s} #{row[1].to_s} 员工表中未找到"
            end
          end

          if @array.size > 0
            puts @array.join("\r\n").red
            puts "警告:有 #{@array.size} 行导入失败，失败率 #{(@array.size*100.0/@count).round(2)}% \r\n\r\n".red
          end

        end
      end

      def self.get_sheet(file_path)
        book = Spreadsheet.open(file_path)
        book.worksheet 0
      end
    end
  end
end
