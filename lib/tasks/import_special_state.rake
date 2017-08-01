namespace :init do
	desc ""
	task import_special_state_for_summary: :environment do
		ActiveRecord::Base.transaction do
			SPECIALSTATETYPE = {
		    '派驻' => 'station_days',
		    '离岗培训' => 'cultivate',
		    '出差' => 'evection',
		    '空勤停飞' => 'ground',
		    '空勤地面' => 'surface_work',
		    'work_days' => {
				    '离岗培训' => 'cultivate_work_days',
				    '出差' => 'evection_work_days',
				    '空勤停飞' => 'ground_work_days',
				    '空勤地面' => 'surface_work_days'
			    }
			}
			puts '开始删除'
		  	delete_count = 0
		  	delete_error = []
		  	special_states = SpecialState.all.inject([]) do |result, special_state|
		  		result << [special_state.employee_id, special_state.special_category, special_state.special_date_from, special_state.special_date_to]
		  		result
		  	end

		  	SpecialState.all.each do |special_state|
		  		count = special_states.count([special_state.employee_id, special_state.special_category, special_state.special_date_from, special_state.special_date_to])
		  		if count > 1
		  			delete_count += 1
		  			delete_error << [special_state.employee_id, special_state.special_category, special_state.special_date_from, special_state.special_date_to]
		  			special_state.destroy
		  			special_states.delete_at(special_states.find_index([special_state.employee_id, special_state.special_category, special_state.special_date_from, special_state.special_date_to]))
		  		end
		  	end

		  	attendances = Attendance.all.inject([]) do |result, attendance|
		  		result << [attendance.record_type, attendance.record_date, attendance.employee_id]
		  		result
		  	end

		  	Attendance.all.each do |attendance|
		  		count = attendances.count([attendance.record_type, attendance.record_date, attendance.employee_id])
		  		if count > 1
		  			delete_count += 1
		  			delete_error << [attendance.record_type, attendance.record_date, attendance.employee_id]
		  			attendance.destroy
		  			attendances.delete_at(attendances.find_index([attendance.record_type, attendance.record_date, attendance.employee_id]))
		  		end
		  	end

		  	flows = Flow.all.inject([]) do |result, flow|
		  		result << [flow.type, flow.receptor_id, flow.workflow_state, flow.start_leave_date, flow.end_leave_date]
		  		result
		  	end

		  	Flow.all.each do |flow|
		  		count = flows.count([flow.type, flow.receptor_id, flow.workflow_state, flow.start_leave_date, flow.end_leave_date])
		  		if count > 1
		  			delete_count += 1
		  			delete_error << [flow.type, flow.receptor_id, flow.workflow_state, flow.start_leave_date, flow.end_leave_date]
		  			flow.destroy
		  			flows.delete_at(flows.find_index([flow.type, flow.receptor_id, flow.workflow_state, flow.start_leave_date, flow.end_leave_date]))
		  		end
		  	end
		  	puts delete_count,delete_error




			puts "开始导入"
			count = 0
			summary_date = "2016-07-01"
			SpecialState.all.each do |special_state|
				next if special_state.special_category == "借调"
				next if !special_state.special_date_to.nil? && special_state.special_date_to.to_date < "2016-07-01".to_date
				next if AttendanceSummary.find_by(employee_id:special_state.employee.id, summary_date: '2016-07').send("#{SPECIALSTATETYPE[special_state.special_category]}").to_i > 0
				count += 1

				if special_state.special_date_to.nil?
		        unless AttendanceSummary.find_by(employee_id:special_state.employee_id, summary_date:summary_date.to_date.strftime("%Y-%m")).nil?
		          if special_state.special_date_from.to_date < summary_date.to_date.beginning_of_month
		            original_total_days = (summary_date.to_date.end_of_month - summary_date.to_date.beginning_of_month).to_i + 1
		            work_days = original_total_days - VacationRecord.check_free_days(summary_date.to_date.beginning_of_month, summary_date.to_date.end_of_month).size
		          else
		            original_total_days = (summary_date.to_date.end_of_month - special_state.special_date_from.to_date).to_i + 1
		            work_days = original_total_days - VacationRecord.check_free_days(special_state.special_date_from.to_date, summary_date.to_date.end_of_month).size
		          end
		          attendance_summary = AttendanceSummary.find_by(employee_id:special_state.employee_id, summary_date:summary_date.to_date.strftime("%Y-%m").to_s)
		          attendance_summary.send("#{SPECIALSTATETYPE[special_state.special_category]}=",attendance_summary.send("#{SPECIALSTATETYPE[special_state.special_category]}").to_i + original_total_days) 
		          if special_state.special_category != "派驻"
		            attendance_summary.send("#{SPECIALSTATETYPE['work_days'][special_state.special_category]}=",attendance_summary.send("#{SPECIALSTATETYPE['work_days'][special_state.special_category]}").to_i + work_days)
		          elsif special_state.special_category == "派驻"
		            if attendance_summary.station_place.nil? || attendance_summary.station_place == ""
		              attendance_summary.station_place = special_state.special_location
		            else
		              attendance_summary.station_place = attendance_summary.station_place + ",#{special_state.special_location}"
		            end
		          end
		          attendance_summary.save
		        end
		      end

		      if !special_state.special_date_to.nil? && special_state.special_date_to.to_date >= summary_date.to_date.beginning_of_month && special_state.special_date_to.to_date <= summary_date.to_date.end_of_month
		        unless AttendanceSummary.find_by(employee_id:special_state.employee_id, summary_date:summary_date.to_date.strftime("%Y-%m").to_s).nil?
		          if special_state.special_date_from.to_date < summary_date.to_date.beginning_of_month
		            original_total_days = (special_state.special_date_to.to_date - summary_date.to_date.beginning_of_month).to_i + 1
		            work_days = original_total_days - VacationRecord.check_free_days(summary_date.to_date.beginning_of_month, special_state.special_date_to.to_date).size
		          else
		            original_total_days = (special_state.special_date_to.to_date. - special_state.special_date_from.to_date).to_i + 1
		            work_days = original_total_days - VacationRecord.check_free_days(special_state.special_date_from.to_date, special_state.special_date_to.to_date).size
		          end
		          attendance_summary = AttendanceSummary.find_by(employee_id:special_state.employee_id, summary_date:summary_date.to_date.strftime("%Y-%m").to_s)
		          attendance_summary.send("#{SPECIALSTATETYPE[special_state.special_category]}=",attendance_summary.send("#{SPECIALSTATETYPE[special_state.special_category]}").to_i + original_total_days) 
		          if special_state.special_category != "派驻"
		            attendance_summary.send("#{SPECIALSTATETYPE['work_days'][special_state.special_category]}=",attendance_summary.send("#{SPECIALSTATETYPE['work_days'][special_state.special_category]}").to_i + work_days)
		          elsif special_state.special_category == "派驻"
		            if attendance_summary.station_place.nil? || attendance_summary.station_place == ""
		              attendance_summary.station_place = special_state.special_location
		            else
		              attendance_summary.station_place = attendance_summary.station_place + ",#{special_state.special_location}"
		            end
		          end
		          attendance_summary.save
		        end
		      end

		      if !special_state.special_date_to.nil? && special_state.special_date_to.to_date > summary_date.to_date.end_of_month
		        unless AttendanceSummary.find_by(employee_id:special_state.employee_id, summary_date:summary_date.to_date.strftime("%Y-%m").to_s).nil?
		          if special_state.special_date_from.to_date < summary_date.to_date.beginning_of_month
		            original_total_days = (summary_date.to_date.end_of_month - summary_date.to_date.beginning_of_month).to_i + 1
		            work_days = original_total_days - VacationRecord.check_free_days(summary_date.to_date.beginning_of_month,summary_date.to_date.end_of_month).size
		          else
		            original_total_days = (summary_date.to_date.end_of_month. - special_state.special_date_from.to_date).to_i + 1
		            work_days = original_total_days - VacationRecord.check_free_days(special_state.special_date_from.to_date, summary_date.to_date.end_of_month).size
		          end
		          attendance_summary = AttendanceSummary.find_by(employee_id:special_state.employee_id, summary_date:summary_date.to_date.strftime("%Y-%m").to_s)
		          attendance_summary.send("#{SPECIALSTATETYPE[special_state.special_category]}=",attendance_summary.send("#{SPECIALSTATETYPE[special_state.special_category]}").to_i + original_total_days) 
		          if special_state.special_category != "派驻"
		            attendance_summary.send("#{SPECIALSTATETYPE['work_days'][special_state.special_category]}=",attendance_summary.send("#{SPECIALSTATETYPE['work_days'][special_state.special_category]}").to_i + work_days)
		          elsif special_state.special_category == "派驻" || attendance_summary.station_place == ""
		            if attendance_summary.station_place.nil?
		              attendance_summary.station_place = special_state.special_location
		            else
		              attendance_summary.station_place = attendance_summary.station_place + ",#{special_state.special_location}"
		            end
		          end
		          attendance_summary.save
		        end
		      end

			end
			puts count
		end

	end
end