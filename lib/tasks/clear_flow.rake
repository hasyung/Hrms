namespace :clear do
  desc "清除流程数据"

  task flow: :environment do
    Flow.destroy_all
    WorkflowEvent.destroy_all

    employee = Employee.find_by(employee_no: '008100')
    attendance_summary = employee.attendance_summaries.find_by(summary_date: "2016-04")
    attendance_summary.update(annual_leave: '0')

    Employee.unscoped.where(employee_no: ["012885", "013052", "013384", "013645"]).update_all(channel_id: 4)
  end
end
