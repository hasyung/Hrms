module Excel
  module Salary
    class HonorSubsidyImporter
      def self.import(file_path)
        puts "$$$ 开始导入员工的飞行安全荣誉，如果员工存在，但是薪酬个人设置不存在会自动创建空的"
        @array = []
        @count = 0
        config = ::Salary.find_by(category: 'allowance')
        if config.present?
          @honor_config_hash = config.form_data['honor_subsidy']
          @sheet = get_sheet(file_path)

          ActiveRecord::Base.transaction do
            @sheet.each_with_index do |row, index|
              next if row[1].to_s.include?('姓名')
              next if row[0].to_s.include?('汇总')
              next if row[1].blank? and row[2].blank?
              @count += 1
              @employee = Employee.unscoped.includes(
                :salary_person_setup
              ).where(
                employee_no: row[2].to_s
              ).first

              if @employee.present?
                @setup = @employee.salary_person_setup || @employee.build_salary_person_setup
                if @honor_config_hash.key(row[3].to_i).present?
                  @setup.update(honor_subsidy: @honor_config_hash.key(row[3].to_i))
                else
                  @array << "#{index +1} 编号#{row[2].to_s} #{row[1].to_s} 标准 #{row[3].to_s}元 在配置表中未找到"
                end
              else
                @array << "#{index +1} 编号#{row[2].to_s} #{row[1].to_s} 在员工表中未找到."
              end
            end
          end
        else
          puts "警告: 导入失败，因为关于飞行安全荣誉津贴的配置为空".red
        end

        if @array.size > 0
          puts @array.join("\r\n").red
          puts "警告: 有 #{@array.size} 行导入失败，失败率 #{(@array.size*100.0/@count).round(2)}% \r\n\r\n".red
        end

      end

      def self.get_sheet(file_path)
        book = Spreadsheet.open(file_path)
        book.worksheet 0
      end
    end
  end
end
