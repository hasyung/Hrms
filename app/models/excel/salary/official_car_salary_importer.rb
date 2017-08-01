module Excel
  module Salary
    class OfficialCarSalaryImporter
      class << self
        def import(file_path)
          SalaryPersonSetup.transaction do
            get_sheet(file_path).each_with_index do |row, index|
              next if [0, 1].include?(index)

              employee = Employee.find_by(employee_no: row[0])

              if employee
                salary_person_setup = employee.salary_person_setup || employee.create_salary_person_setup
                salary_person_setup.update!(official_car: row[10])
              else
                puts "#{index + 1} #{row[2]} #{row[0]}"
              end
            end
          end
        end

        private
        def get_sheet(file_path)
          book = Spreadsheet.open(file_path)
          book.worksheet 0
        end
      end
    end
  end
end
