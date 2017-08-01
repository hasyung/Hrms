json.department do
  json.id            @department.id
  json.name          @department.name
  json.grade         @department.grade
  json.status        @department.status || "active"
  json.serial_number @department.serial_number
  json.xdepth        @department.depth

  json.parent_id @department.parent_id
  json.nature_id @department.nature_id
  json.sort_no   @department.sort_no
end
