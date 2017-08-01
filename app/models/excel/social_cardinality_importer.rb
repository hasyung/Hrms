require 'spreadsheet'

module Excel
  class SocialCardinalityImporter
    attr_reader :values, :error_count, :month

    def initialize(file_path, month)
      @book = Spreadsheet.open("#{Rails.root}/public/#{file_path}")
      # @book = Spreadsheet.open(file_path)
      htz_sheet = @book.worksheet("合同制")
      htg_sheet = @book.worksheet("合同工")
      cqhtz_sheet = @book.worksheet("重庆合同制")
      cqhtg_sheet = @book.worksheet("重庆合同工")
      ty_sheet = @book.worksheet("退养")

      @file_path = file_path
      @sheets = [htz_sheet, htg_sheet, cqhtg_sheet, cqhtz_sheet, ty_sheet]
      @month = month
      @error_count = 0
      @values = []
    end

    def import
      @sheets.each do |sheet|
        parse_data(sheet)
      end

      column_names = %w(employee_id import_month import_date employee_no employee_name
        department_name position_name social_account total)
      cardinalities = SocialCardinality.where("import_month = '#{month}'")
      cardinalities.delete_all if cardinalities.present?

      SocialCardinality.import(column_names, @values)

      path = "#{@file_path.gsub(".xls", "")}_#{Time.now.to_s(:db)}.xls"
      @book.write("#{Rails.root}/public#{@file_path}_#{Time.now.to_s(:db)}.xls")
      {
        success_count: @sheets.map(&:count).sum - @error_count - 1,
        error_count: @error_count,
        file: Setting.upload_url + path
      }
    end

    def parse_data(sheet)

      sheet.each_with_index do |row, index|
        # binding.pry
        next if index == 0

        employee = Employee.find_by(employee_no: row[0], name: row[1])

        if employee.blank?
          @error_count += 1
          sheet.row(index).push("找不到该员工，请核对")
        else
          amount = columns_for(sheet).inject(0) do |result, index| 
            col_val = row[index].respond_to?(:value) ? row[index].value : row[index]
            result += (col_val.nil? ? 0 : col_val.to_f)
            result
          end
          
          value = [employee.id, @month, @month + "-01", employee.employee_no, employee.name, employee.department.full_name,
            employee.master_position.name, row[68], amount
          ]
          @values.push(value)
        end
      end
    end

    def columns_for(sheet)
      {
        "合同制" => [37, 46, 47],
        "合同工" => [34, 43, 44, 45, 46],
        "重庆合同制" => [38, 47, 48],
        "重庆合同工" => [35, 44, 45, 46, 47],
        "退养" => [16, 25, 26]
      }[sheet.name]
    end
  end
end
