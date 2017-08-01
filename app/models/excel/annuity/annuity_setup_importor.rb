module Excel
  module Annuity
    class AnnuitySetupImportor
      def self.import_annuity_account(file_path)
        puts "$$$ 开始导入员工年金保险公司年金账户名单..."
        @array = []
        @count = 0
        @sheet = get_sheet file_path
        ActiveRecord::Base.transaction do
          @sheet.each_with_index do |row, index|
            next if row[2].to_s.include?('姓名')
            next if row[5].class == Spreadsheet::Excel::Error
            @count += 1
            @employee = Employee.unscoped.where(
              "employee_no = ? OR identity_no = ?",
              row[5].to_s,
              row[4].to_s
            ).first

            if @employee.present? && @employee.name.include?(row[2].to_s.strip)
              @employee.update(annuity_account_no: "0")
            else
              @array << "#{index + 1} #{row[5].to_s} #{row[2].to_s} 在员工表中未找到"
            end
          end
        end

        if @array.size > 0
          puts @array.join("\r\n").red
          puts "警告:有 #{@array.size} 行导入失败，失败率 #{(@array.size*100.0/@count).round(2)}% \r\n\r\n".red
        end
      end

      def self.import_annuity_info(file_path)
        puts "准备导入年金缴费详情中的年金基数，年金缴费状态..."
        @array = []
        @count = 0
        @sheet = get_sheet file_path
        ActiveRecord::Base.transaction do
          @sheet.each_with_index do |row, index|
            next if row[2].to_s.include?('编码')
            next if row[2].to_s.blank?
            @count += 1
            @employee = Employee.unscoped.where(
              employee_no: row[2].to_s
            ).first

            if @employee.present? && @employee.name.include?(row[6].to_s.strip)
              @employee.update(
                annuity_cardinality: row[10],
                annuity_status: row[11].to_f ? true : false
              )
            else
              @array << "#{index + 1} #{row[2].to_s} #{row[6].to_s} 在员工表中未找到"
            end
          end
        end

        if @array.size > 0
          puts @array.join("\r\n").red
          puts "警告:有 #{@array.size} 行导入失败，失败率 #{(@array.size*100.0/@count).round(2)}% \r\n\r\n".red
        end
      end

      def self.get_sheet(file_path)
        book = Spreadsheet.open file_path
        book.worksheet 0
      end
    end
  end
end
