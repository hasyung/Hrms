namespace :attendance_summary do
	desc "修复工作日计算错误的大BUG"
	task fix_work_days_for_attendance_summary: :environment do
		work_days = {
			"Flow::PersonalLeave" => "personal_leave_work_days",
			"Flow::SickLeaveNulliparous" => "sick_leave_work_days",
			"Flow::SickLeaveInjury" => "sick_leave_work_days",
			"Flow::SickLeave" => "sick_leave_work_days",
			"Flow::AnnualLeave" => "annual_leave",
			"Flow::OffsetLeave" => "offset_leave"
		}

		paid_leave = [
			"Flow::AnnualLeave",
			"Flow::OffsetLeave"
		]

		other_leave = [
			"Flow::SickLeave",
			"Flow::SickLeaveInjury",
			"Flow::SickLeaveNulliparous",
			"Flow::PersonalLeave"
		]

		holidays = Holiday.pluck("record_date").map(&:to_s)
		count = 0
		ActiveRecord::Base.transaction do 
			Flow.find_each(batch_size: 3000).each_with_index do |flow, index|
				if other_leave.include?(flow.type)
					if [0,6].include?(flow.start_leave_date.wday) && flow.workflow_state == "actived" && flow.leave_date_record.first.last["start_time"] =~ /13:30:00/
					    attendance_summary = AttendanceSummary.find_by(employee_id: flow.receptor_id,summary_date: flow.start_leave_date.strftime("%Y-%m"))
						attendance_summary.send("#{work_days[flow.type]}=", eval(attendance_summary.send("#{work_days[flow.type]}")) + 0.5)
						attendance_summary.save
						count += 1
					end
					if [0,6].include?(flow.start_leave_date.wday) && flow.workflow_state == "actived" && flow.leave_date_record.to_a.last.last["end_time"] =~ /13:30:00/
						attendance_summary = AttendanceSummary.find_by(employee_id: flow.receptor_id,summary_date: flow.end_leave_date.strftime("%Y-%m"))
						attendance_summary.send("#{work_days[flow.type]}=", eval(attendance_summary.send("#{work_days[flow.type]}")) + 0.5)
						attendance_summary.save
						count += 1
					end
				end

				if paid_leave.include?(flow.type)
					if holidays.include?(flow.start_leave_date) && flow.workflow_state == "actived" && flow.leave_date_record.first.last["start_time"] =~ /13:30:00/
					    attendance_summary = AttendanceSummary.find_by(employee_id: flow.receptor_id,summary_date: flow.start_leave_date.strftime("%Y-%m"))
						attendance_summary.send("#{work_days[flow.type]}=", eval(attendance_summary.send("#{work_days[flow.type]}")) + 0.5)
						attendance_summary.save
						count += 1
						next
					end
					if holidays.include?(flow.start_leave_date) && flow.workflow_state == "actived" && flow.leave_date_record.to_a.last.last["end_time"] =~ /13:30:00/
						attendance_summary = AttendanceSummary.find_by(employee_id: flow.receptor_id,summary_date: flow.end_leave_date.strftime("%Y-%m"))
						attendance_summary.send("#{work_days[flow.type]}=", eval(attendance_summary.send("#{work_days[flow.type]}")) + 0.5)
						attendance_summary.save
						count += 1
					end
				end
				puts count
			end
		end
	end

	desc "给邓辉消已生效的假"
	task fix_deng_hui_summary: :environment do
		flow = Flow.find_by(id: 16488)
		employee = Employee.find_by(id: flow.receptor_id)
		vacation_record = employee.vacation_records.where(record_type: "补休假").last
		days = vacation_record.days.to_f + 0.5
		vacation_record.update(days: days)
		# attendance_summary = AttendanceSummary.where(summary_date: "2016-10", employee_id: flow.receptor_id).first
		# attendance_summary.update(offset_leave: (attendance_summary.offset_leave.to_f - 0.5).to_s)
		flow.destroy
	end
































end