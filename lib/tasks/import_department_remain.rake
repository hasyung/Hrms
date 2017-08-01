namespace :import do
  desc "import department_salary remain"
  task department_remain: :environment do
    month = '2016-05'

    book = Spreadsheet.open("#{Rails.root}/public/department_remain.xls")
    sheet = book.worksheet 0

    DepartmentSalary.transaction do
      DepartmentSalary.where(month: month).update_all(remain:0, leader_remain:0, employee_remain:0)

      sheet.each_with_index do |row, index|
        next if [0, 1, 2].include?(index)

        department = Department.find_by(name: row[0].to_s.split(/[-|—]/).first)
        if department
          salary = department.department_salaries.find_or_create_by(month: month)
          salary.update(
            remain:          salary.remain.to_f + row[7].value.to_f,
            leader_remain:   salary.leader_remain.to_f + row[15].value.to_f,
            employee_remain: salary.employee_remain.to_f + row[22].value.to_f
          )
        end
      end
    end
  end
end