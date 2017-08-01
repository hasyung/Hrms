namespace :init do
  desc "临时生成这个月的考勤汇总数据"

  task attendance_summary: :environment do 
    summary_date = Date.today.strftime("%Y-%m")
    status_manager = AttendanceSummaryStatusManager.where(summary_date: summary_date)

    if status_manager.count == 0
      departments = Department.where(depth: 2)

      departments.each do |department|
        attendance_summary_status_manager = AttendanceSummaryStatusManager.create(department_id: department.id, department_name: department.name, summary_date: Date.today.strftime("%Y-%m"))
        department_ids = Department.where('serial_number like ?', "#{department.serial_number}%").pluck(:id)

        department_ids.each do |department_id|
          Employee.where(department_id: department_id).each do |employee|
            attendance_summary_status_manager.attendance_summaries.create(
              employee_id: employee.id,
              employee_name: employee.name,
              employee_no: employee.employee_no,
              department_id: department_id,
              department_name: employee.department.full_name,
              labor_relation: employee.labor_relation.display_name
            )
          end
        end
      end
    end
  end
end