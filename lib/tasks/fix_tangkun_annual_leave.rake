namespace :fix do
  desc "修复唐琨的年假"

  task tangkun_annual_leave: :environment do
    emp = Employee.find_by(employee_no: '003527')
    flow = emp.flows.first

    flow.start_time = flow.start_time.sub("T13:00:00+08:00", "T13:30:00+08:00")
    flow.workflow_state = "repeal"

    record_data = flow.leave_date_record.inject({}) do |result, (month, form_data)|
      form_data["start_time"] = form_data["start_time"].sub("T13:00:00+08:00", "T13:30:00+08:00")
      result[month] = form_data
      result
    end

    flow.leave_date_record = record_data
    flow.save

    records = flow.leave_date_record.values
    vacation_days = records.inject(0) do |days, record|
      days += record["vacation_days"]
      days
    end

    emp.add_year_days(vacation_days, 2015)

    attendance_summary = emp.attendance_summaries.last
    attendance_summary.update(annual_leave: 0, paid_leave: 0)
  end

  desc "撤销已经生效的假期"
  task repeal_vacation: :environment do
    emp = Employee.find_by(employee_no: "007705")
    flows = emp.flows.where(type: 'Flow::SickLeave')
    flows.each do |flow|
      flow.workflow_state = 'repeal'

      flow.leave_date_record.each do |month, record|
        AttendanceCalculator.reduce_leave_days(flow.type, record["vacation_days"], flow.receptor)
      end

      leave_date_record = flow.leave_date_record.inject({}) do |result, (month, form_data)|
        form_data['vacation_days'] = 0
        result[month] = form_data
        result
      end
      flow.leave_date_record = leave_date_record
      flow.save
    end
  end

  desc "修复现有流程的13点的数据问题"

  task flow_data: :environment do
    Flow.all.each do |flow|
      flow.start_time = flow.start_time.sub("T13:00:00+08:00", "T13:30:00+08:00")
      flow.end_time = flow.end_time.sub("T13:00:00+08:00", "T13:30:00+08:00")

      result = flow.leave_date_record.inject({}) do |result, (month, form_data)|
        form_data["start_time"] = form_data["start_time"].sub("T13:00:00+08:00", "T13:30:00+08:00")
        form_data["end_time"] = form_data["end_time"].sub("T13:00:00+08:00", "T13:30:00+08:00")
        result[month] = form_data

        result
      end

      flow.leave_date_record = result

      flow.save
    end
  end
end
