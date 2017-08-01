require 'spreadsheet'

module Excel
  class EducationExperienceExportor

    class << self

      def export(records)
        book = Spreadsheet.open("#{Rails.root}/public/template/education_experience.xls")
        sheet = book.worksheet(0)

        records.each_with_index do |record, index|
          employee = record.employee || Employee.unscoped.find_by(id: record.employee_id)

          sheet[index + 1, 0] = index + 1
          sheet[index + 1, 1] = record.employee_name
          sheet[index + 1, 2] = record.department_name
          sheet[index + 1, 3] = EmployeePosition.full_position_name(employee.try(:employee_positions).to_a)
          sheet[index + 1, 4] = employee.try(:identity_no)
          sheet[index + 1, 5] = record.employee_no
          sheet[index + 1, 6] = employee.try(:labor_relation).try(:display_name)
          sheet[index + 1, 7] = record.school
          sheet[index + 1, 8] = record.major
          sheet[index + 1, 9] = record.education_background.try(:display_name)
          sheet[index + 1, 10] = record.degree.try(:display_name)
          sheet[index + 1, 11] = record.graduation_date.to_s(:db)
          sheet[index + 1, 12] = record.change_date.to_s(:db)
        end

        filename = "学历变更导出表.xls"
        book.write("#{Rails.root}/public/export/tmp/#{filename}")
        {
          path: "#{Rails.root}/public/export/tmp/#{filename}",
          filename: filename
        }
      end

    end
  end
end