require 'spreadsheet'

module Excel
  class WelfareFeeImportor

    def self.import(file_path)
      sheet = get_sheet(file_path)
      values, months = [], []

      WelfareFee.transaction do
        sheet.each_with_index do |row, index|
          next if index == 0

          begin
            (row[0] + '-01').to_date
          rescue Exception => e
            return "时间填写格式有误"
          end

          values << [row[0], '福利费', row[1].to_f]
          values << [row[0], '社会保险费', row[2].to_f]
          values << [row[0], '公积金', row[3].to_f]
          values << [row[0], '企业年金', row[4].to_f]

          months << row[0]
        end

        WelfareFee.where("month in (?)", months).delete_all
        WelfareFee.import(WelfareFee::COLUMNS, values, validate: false)
      end

      "导入成功"
    end

    private

    def self.get_sheet(file_path)
      book = Spreadsheet.open("#{Rails.root}/public/#{file_path}")
      book.worksheet 0
    end

  end
end