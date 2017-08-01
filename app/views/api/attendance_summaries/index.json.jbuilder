json.attendance_summaries @attendance_summaries do |attendance_summary|
  json.id                        attendance_summary.id
  json.department_name           attendance_summary.department_name
  json.employee_id               attendance_summary.employee_id
  json.employee_no               attendance_summary.employee_no
  json.employee_name             attendance_summary.employee_name
  json.labor_relation            attendance_summary.labor_relation
  json.paid_leave                attendance_summary.paid_leave
  json.sick_leave                attendance_summary.sick_leave
  json.sick_leave_injury         attendance_summary.sick_leave_injury
  json.sick_leave_nulliparous    attendance_summary.sick_leave_nulliparous
  json.sick_days                 attendance_summary.sick_leave.to_f + attendance_summary.sick_leave_injury.to_f + attendance_summary.sick_leave_nulliparous.to_f
  json.sick_work_days            attendance_summary.sick_leave_work_days
  json.personal_leave            attendance_summary.personal_leave
  json.personal_leave_work_days  attendance_summary.personal_leave_work_days
  json.home_leave                attendance_summary.home_leave
  json.home_leave_work_days      attendance_summary.home_leave_work_days
  json.cultivate                 attendance_summary.cultivate
  json.cultivate_work_days       attendance_summary.cultivate_work_days
  json.evection                  attendance_summary.evection
  json.evection_work_days        attendance_summary.evection_work_days
  json.absenteeism               attendance_summary.absenteeism
  json.late_or_leave             attendance_summary.late_or_leave
  json.ground                    attendance_summary.ground
  json.flight_grounded_work_days attendance_summary.ground_work_days
  json.surface_work              attendance_summary.surface_work
  json.station_days              attendance_summary.station_days
  json.station_place             attendance_summary.station_place
  json.remark                    attendance_summary.remark
  json.annual_leave              attendance_summary.annual_leave
  json.marriage_funeral_leave    attendance_summary.marriage_funeral_leave
  json.prenatal_check_leave      attendance_summary.prenatal_check_leave
  json.accredit_leave            attendance_summary.accredit_leave
  json.rear_nurse_leave          attendance_summary.rear_nurse_leave
  json.family_planning_leave     attendance_summary.family_planning_leave
  json.women_leave               attendance_summary.women_leave
  json.maternity_leave           attendance_summary.maternity_leave
  json.recuperate_leave          attendance_summary.recuperate_leave
  json.injury_leave              attendance_summary.injury_leave
  json.lactation_leave           attendance_summary.lactation_leave
  json.public_leave              attendance_summary.public_leave
  json.offset_leave              attendance_summary.offset_leave
  json.summary_date              attendance_summary.summary_date
end

json.partial! 'shared/page_basic'
