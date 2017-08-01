require 'spreadsheet'

# Excel::Salary::CommunicateAllowanceImportor.import("文件路径")

module Excel
    module Salary
      class CommunicateAllowanceImportor
        def self.import(file_path)
          @array = []
          @count = 0

          sheet = get_sheet(file_path)

          puts "$$$ 开始导入员工的通讯补贴，如果员工存在，但是薪酬个人设置不存在会自动创建空的"
          # puts "按回车键继续..."
          # STDIN.readline

          Employee.transaction do
            # eager_load
            @employee_hash = Employee.includes(:salary_person_setup).references(:salary_person_setup).index_by(&:employee_no)

            sheet.each_with_index do |row, index|
              next if row[0].to_s.include?("标签")
              printf("*".green) if @count % 100 == 0
              @count += 1

              employee_no = row[1].to_s
              employee_name = row[3].to_s

              @employee = @employee_hash[employee_no]


              if @employee.present?

                @allowance = row[12].to_f
                @position_communication_fee  = @employee.positions.map(&:communicate_allowance).max
                @duty_rank_communication_fee = @employee.duty_rank.try(:communicate_allowance).to_f

                @setup = @employee.salary_person_setup || @employee.build_salary_person_setup
                if @allowance == @position_communication_fee || @allowance == @duty_rank_communication_fee
                  @communicate_allowance = nil
                else
                  @communicate_allowance = @allowance
                end

                @setup.import_mode = true
                @setup.update(communicate_allowance: @communicate_allowance)
              else
                @array << "#{index + 1} #{employee_name} #{employee_no}"
              end
            end
          end

          if @array.size > 0
            puts @array.join("\r\n").red
            puts "提示: 总共处理 #{@count} 行数据".yellow
            puts "警告: 有#{@array.size}行导入失败，失败率 #{(@array.size * 100.0/@count).round(2)}% \r\n\r\n".red
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
