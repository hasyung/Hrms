require 'spreadsheet'

module Excel
  class BusFeeImporter
    def self.import(file_path)
      sheet = get_sheet(file_path)
      puts sheet.count

      error_names, error_count, success_count = [], 0, 0

      Employee.transaction do
        sheet.each_with_index do |row, index|
          next if index == 0 || %w(姓名 人员编号 乘车日期 停坐日期 标准 备注).include?(row[0])
          next if !row[1] || row[1].size != 6
          puts row[0], row[1]
          employee = Employee.find_by(employee_no: row[1])

          if employee.blank?
            error_names << row[1]
            error_count += 1
          else
            fee = row[4]
            fee = 0 if fee == '放弃'
            success_count += 1 if employee.update!(bus_fee: fee)
          end
        end
      end

      {
        success_count: success_count,
        error_count: error_count,
        error_names: error_names
      }
    end

    private
    def self.get_sheet(file_path)
      book = Spreadsheet.open("#{Rails.root}/public/#{file_path}")
      book.worksheet 0
    end
  end
end