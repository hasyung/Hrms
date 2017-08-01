require 'spreadsheet'

module Excel
  class SocialSetupImportor

    def self.import(file_path)
      sheet = get_sheet(file_path)

      error_names, error_count = [], 0
      social_location = '成都'

      puts "$$$ 开始导入员工的社保个人设置，如果员工存在，但是社保个人设置不存在会自动创建空的"

      SocialPersonSetup.transaction do
        sheet.each_with_index do |row, index|
          if %w(北京外站 深圳外站 广州外站 上海外站 杭州外站 重庆分公司).include?(row[0])
            social_location = row[0].first(2)
            next
          end

          printf("*") if index % 100 == 0
          next if index == 0 || row[0].blank?
          employee = Employee.find_by(employee_no: row[0])

          if employee.blank?
            error_names << "#{row[0]} #{row[2]}"
            error_count += 1
          else
            setup = employee.social_person_setup || employee.build_social_person_setup
            attributes = {
              social_location: social_location,
              pension: true,
              treatment: true,
              unemploy: true,
              injury: true,
              illness: true,
              fertility: true,
              social_account: row[1],
              pension_cardinality: row[3],
              treatment_cardinality: row[4]
            }
            setup.assign_attributes(attributes)
            setup.save
          end
        end
      end

      if error_count > 0
        puts error_names.join("\r\n").red
        puts "提示: 总共处理 #{sheet.count - 1} 行数据".yellow
        puts "警告: 有 #{error_count} 行导入失败，失败率 #{(error_count * 100.0/(sheet.count - 1)).round(2)}% \r\n\r\n".red
      end
    end

    private
    def self.get_sheet(file_path)
      book = Spreadsheet.open(file_path)
      book.worksheet 0
    end

  end
end