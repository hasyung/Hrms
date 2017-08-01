require 'spreadsheet'

# Excel::Salary::PerformanceImportor.import("文件路径")

module Excel
    module Salary
      class PerformanceImportor
        def self.import(file_path)
          @array = []
          @count = 0

          sheet = get_sheet(file_path)

          puts "$$$ 开始导入员工的考核性收入，如果员工存在，但是薪酬个人设置不存在会自动创建空的"
          # puts "按回车键继续..."
          # STDIN.readline

          @salary_hash = ::Salary.where("category LIKE '%_perf'").index_by(&:category)

          Employee.transaction do
            # eager_load
            @employee_hash = Employee.unscoped.includes(:salary_person_setup, :category).references(:salary_person_setup).index_by(&:employee_no)

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

                @category = row[2].to_s
                @perf_result = row[16].to_s
                @amount = row[19].round.to_f
                @performance_wage = nil

                if @category == "信息"
                  @performance_wage = @employee.is_leader? ? "information_leader_perf" : "information_perf"
                elsif @category == "航务航材"
                  @performance_wage = @employee.is_leader? ? "material_leader_perf" : "airline_business_perf"
                elsif ["管理", "营销"].include?(@category)
                  @performance_wage = @employee.is_leader? ?  "market_leader_perf" : "manage_market_perf"
                elsif @category == "机务" && row[7].blank?
                  @performance_wage = @employee.is_leader? ? "service_leader_perf" : "service_normal_perf"
                elsif @category == "服务C-1"
                  @performance_wage = "service_c_1_perf"
                elsif @category == "服务C-2"
                  @performance_wage = "service_c_2_perf"
                elsif @category == "服务C-3"
                  @performance_wage = "service_c_3_perf"
                elsif @category == "服务C-驾驶"
                  @performance_wage = "service_c_driving_perf"
                end

                if @performance_wage.blank? or @salary_hash[@performance_wage].blank?
                  @array << "#{index + 1} #{employee_name} #{employee_no}"
                  next
                end

                @amount_hash = {}
                @salary_hash[@performance_wage][:form_data]["flags"].each do |grade, config|
                  @amount_hash[config['amount'].to_i] = grade
                end

                if @employee.join_scal_date > Date.new(2013,12,31)
                  @performance_channel = 'E' # 随动
                elsif @perf_result == '优秀'
                  @performance_channel = 'A'
                elsif @perf_result == '良好'
                  @performance_channel = 'B'
                elsif @perf_result == '合格'
                  @performance_channel = 'C'
                elsif @perf_result.blank?
                  @performance_channel = 'D' # 随动
                end

                hash = {
                  performance_wage:    @performance_wage,
                  performance_money:   @amount,
                  performance_flag:    @amount_hash[@amount.to_i].to_i,
                  performance_channel: @performance_channel
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
