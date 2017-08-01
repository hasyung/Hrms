require 'spreadsheet'

module Excel
  class NightFeeImporter
    # 导入夜餐费次数记录表
    def self.import(file_path, month)
      sheet = get_sheet(file_path)
      NightRecord.where(month: month).delete_all

      NightRecord.transaction do
        sheet.each_with_index do |row, index|
          next if row[0].blank?
          next if row[0].to_s.include?("序号")

          @employee_no = row[1]
          @employee_name = row[2]
          next if !@employee_no || !@employee_name

          hash = {
            employee_name: @employee_name,
            employee_no: @employee_no,
            no: row[0],
            first_department: row[3],
            shifts_type: row[4],
            location: row[5],
            night_number: row[6],
            notes: row[7].to_s.strip,
            subsidy: row[8],
            amount: row[9].value,
            flag: row[10].to_s.strip,
            month: month
          }

          NightRecord.create(hash)
        end
      end
    end

    def self.get_sheet(file_path)
      book = Spreadsheet.open("#{Rails.root}/public/#{file_path}")
      book.worksheet 0
    end
  end
end
