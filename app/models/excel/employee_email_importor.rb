require 'spreadsheet'

module Excel
  class EmployeeEmailImportor

    def self.import(file_path)
      sheet = get_sheet(file_path)

      error_names, error_count = [], 0
      @employee_hash = Employee.includes(:contact).index_by(&:employee_no)

      puts "****** 开始导入员工邮箱 ******"

      Employee::ContactWay.transaction do
        sheet.each_with_index do |row, index|
          next if index == 0 || row[1].blank?

          employee = @employee_hash[row[0].to_s]

          if employee.blank?
            puts "第 #{index + 1} 行，员工号 #{row[0]} 不存在"
            error_count += 1
          else
            contact = employee.contact || employee.build_contact
            contact.email = row[1].to_s
            contact.save_without_auditing
          end
        end
      end

      if error_count > 0
        puts "提示: 总共处理 #{sheet.count - 1} 行数据 \r\n".yellow
        puts "警告: 有 #{error_count} 行导入失败，失败率 #{error_count * 100/(sheet.count - 1)}% \r\n\r\n".red
      end
    end

    private

    def self.get_sheet(file_path)
      book = Spreadsheet.open("#{Rails.root}/public/#{file_path}")
      book.worksheet 0
    end
  end
end