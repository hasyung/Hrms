module Excel


  class WelfareBudgetImportor
    def self.import(file_path)
      sheet = get_sheet(file_path)

      values, years = [], []

      WelfareBudget.transaction do
        sheet.each_with_index do |row , index|
          next if index == 0
          begin
            year = row[0].to_i

            if year > 2050 || year < 2000
              return "时间填写格式有误"
            end

          rescue Exception => e
            return "时间填写格式有误"
          end
          values << [year, '福利费', row[1].to_f]
          values << [year, '社会保险费', row[2].to_f]
          values << [year, '公积金', row[3].to_f]
          values << [year, '企业年金', row[4].to_f]
          years << year
        end

        WelfareBudget.where("year in (?)",years).delete_all
        WelfareBudget.import(WelfareBudget::COLUMNS, values, validate: false)
      end
      "导入成功"
    end

    def self.get_sheet(file_path)
      book = Spreadsheet.open("#{Rails.root}/public/#{file_path}")
      book.worksheet 0
    end
  end
end