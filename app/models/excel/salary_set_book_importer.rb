require 'spreadsheet'

module Excel
  class SalarySetBookImporter
    def self.import(file_path)
      sheet = get_sheet(file_path)
      @sqls = []

      Employee.transaction do
        sheet.each_with_index do |row, index|
          next if row[0].include?("人员编码")

          @employee_no = row[0]
          @employee_name = row[1]
          @set_book = row[2]

          @sqls << "UPDATE employees SET salary_set_book='#{@set_book}' WHERE name='#{@employee_name}' AND employee_no='#{@employee_no}'"
        end

        @sqls.each {|sql| ActiveRecord::Base.connection.execute(sql)}
      end

      nil
    end

    def self.get_sheet(file_path)
      book = Spreadsheet.open("#{Rails.root}/public/#{file_path}")
      book.worksheet 0
    end
  end
end