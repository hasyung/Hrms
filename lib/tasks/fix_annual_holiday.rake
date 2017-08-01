require "spreadsheet"
namespace :fix do
  desc "修复转部门人员2016年的年假"

  task annual_holiday: :environment do
    datas = [
      {
        filename: "休2016年年假情况.xlsx",
        year: "2016"
      }
    ]

    datas.each do |data|
      puts "=========导入#{data[:filename]}========="
      sheet = Spreadsheet.open("#{Rails.root}/public/#{data[:filename]}").worksheet(0)

      sheet.each_with_index do |row, index|
        next if index == 0

        employee = Employee.find_by(employee_no: row[5], name: row[4])

        if employee
          vacation_record = VacationRecord.find_or_create_by(employee_id: employee.id, record_type: "年假", year: data[:year])
          vacation_record.update(days: row[14])
        else
          puts "#{index + 1} #{row[4]} #{row[5]}"
        end
      end
    end
  end

  desc "特殊人员年假初始化"
  task holiday_init_for_special: :environment do
    names = {
      '000323' => 15,
      '002105' => 15,
      '007446' => 5,
      '000535' => 3.5,
      '000321' => 15,
      '012184' => 11,
    }
    names.keys.each do |name|
      employee = Employee.find_by(employee_no: name)
        if employee
          vacation_record = VacationRecord.find_or_create_by(employee_id: employee.id, record_type: "年假", year: '2016')
          vacation_record.update(days: names[name])
          #vacation_record.increment!(:days, names[name])
        else
          puts "error #{name}"
        end
    end
  end
end
