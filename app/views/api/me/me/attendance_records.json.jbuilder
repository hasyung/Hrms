json.attendance_records do
  json.leaves @leaves do |leave|
    json.id leave.id
    json.title leave.name
    json.start leave.start_time
    json.end leave.try(:end_time)
  end

  json.late_or_early_leaves @late_or_early_leaves do |leave|
    json.id leave.id
    json.title leave.record_type
    json.start leave.record_date
  end

  json.absences @absences do |leave|
    json.id leave.id
    json.title leave.record_type
    json.start leave.record_date
  end

  json.lands []
  json.off_post_trains []

  json.flight_groundeds @flight_groundeds do |leave|
    json.id leave.id
    json.title leave.record_type
    json.start leave.record_date
  end

  json.flight_ground_works @flight_ground_works do |leave|
    json.id leave.id
    json.title leave.record_type
    json.start leave.record_date
  end

  json.vacations @employee.vacation_summary
end
