json.attendance do
  json.id @attendance.id
  json.record_type @attendance.record_type
  json.record_date @attendance.record_date
end
