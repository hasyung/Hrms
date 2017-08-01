module Excel
  module Salary
    class PlacementSubsidyImporter
      def self.import(file_path)
        @array = []
        @sheet = get_sheet(file_path)

        puts "$$$ 开始导入员工的安置补贴，如果员工存在，但是薪酬个人设置不存在会自动创建空的"

        ActiveRecord::Base.transaction do
          @count = 0
          @sheet.each_with_index do |row, index|
            next if row[1].to_s.include?('姓名')
            next if row[1].to_s.blank?
            @count += 1
            @employee = Employee.unscoped.includes(
              :salary_person_setup
            ).where(
              name: row[1].to_s
            ).first

            if @employee.present?
              @setup = @employee.salary_person_setup || @employee.build_salary_person_setup
              @setup.update(placement_subsidy: true)
            else
              @array << "#{index+1}行 #{row[1].to_s} 在员工表中未找到."
            end
          end
        end

        if @array.size > 0
          puts @array.join("\r\n").red
          puts "提示: 总共处理 #{@count} 行数据".yellow
          puts "警告: 有 #{@array.size} 行导入失败，失败率 #{@array.size * 100/@count}% \r\n\r\n".red
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
