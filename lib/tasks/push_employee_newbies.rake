require 'spreadsheet'

namespace :push do
  desc "推送新员工异动纪录"

  task employee_newbies: :environment do
    sheet = Spreadsheet.open("#{Rails.root}/public/push_employee_newbies.xls").worksheet(0)

    sheet.each_with_index do |row, index|
      next if index == 0

      employee = Employee.find_by(name: row[4], employee_no: row[5])

      if employee
        change_record = ChangeRecord.where(change_type: 'employee_newbie').where("change_data like ?", "%#{employee.employee_no}%").first
        change_record.destroy if change_record.present?
        change_record = nil

        unless change_record
          change_record = ChangeRecord.save_record('employee_newbie', employee)
          change_record.update(event_time: employee.created_at)
        end
        change_record.send_notification
      else
        puts "#{index + 1}: 人员#{row[4]}不存在"
      end
    end
  end
end
