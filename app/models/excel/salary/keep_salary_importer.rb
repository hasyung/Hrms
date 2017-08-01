require 'spreadsheet'

# Excel::Salary::KeepSalaryImporter.import("文件路径")

module Excel
    module Salary
      class KeepSalaryImporter
        def self.import(file_path)
          @array = []
          @count = 0

          sheet = get_sheet(file_path)

          puts "$$$ 开始导入员工的保留工资，如果员工存在，但是薪酬个人设置不存在会自动创建空的"
          # puts "按回车键继续..."
          # STDIN.readline

          Employee.transaction do
            # eager_load
            @employee_hash = Employee.includes(:salary_person_setup).references(:salary_person_setup).index_by(&:employee_no)

            sheet.each_with_index do |row, index|
              next if row[0].to_s.include?("人员编码")
              printf("*".green) if @count % 100 == 0
              @count += 1

              employee_no = row[0].to_s
              employee_name = row[1].to_s

              @employee = @employee_hash[employee_no]

              if @employee.present?
                if @employee.salary_person_setup.nil?
                  @setup = @employee.build_salary_person_setup
                else
                  @setup = @employee.salary_person_setup
                end

                @position_keep            = row[7].to_f
                @keep_performance         = row[8].to_f
                @keep_working_years       = row[9].to_f
                @keep_minimum_growth      = row[10].to_f
                @keep_land_allowance      = row[11].to_f
                @keep_life_1              = row[12].to_f
                @keep_life_2              = row[13].to_f
                @keep_adjustment_09       = row[14].to_f
                @keep_bus_14              = row[15].to_f
                @keep_communication_14    = row[16].to_f

                hash = {
                  keep_position:          @position_keep,
                  keep_performance:       @keep_performance,
                  keep_working_years:     @keep_working_years,
                  keep_minimum_growth:    @keep_minimum_growth,
                  keep_land_allowance:    @keep_land_allowance,
                  keep_life_1:            @keep_life_1,
                  keep_life_2:            @keep_life_2,
                  keep_adjustment_09:     @keep_adjustment_09,
                  keep_bus_14:            @keep_bus_14,
                  keep_communication_14:  @keep_communication_14
                }

                @setup.import_mode = true
                @setup.update(hash)
              else
                @array << "#{index + 1} #{employee_name} #{employee_no}"
              end
            end
          end

          if @array.size > 0
            puts @array.join("\r\n").red
            puts "提示: 总共处理 #{@count} 行数据".yellow
            puts "警告: 有 #{@array.size} 行导入失败，失败率 #{(@array.size * 100.0/@count).round(2)}% \r\n\r\n".red
          end
        end

        private

        def self.get_sheet(file_path)
          book = Spreadsheet.open(file_path)
          book.worksheet 0
        end
      end
    end
end
