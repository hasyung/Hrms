json.departments @departments do |department|
  json.id            department.id
  json.name          department.name
  json.grade         department.grade
  json.grade_id      department.grade_id
  json.status        department.status          ||   "active"
  json.serial_number department.serial_number
  json.xdepth        department.depth
  json.sort_no       department.sort_no
  json.is_stick      department.is_stick
  json.set_book_no   department.set_book_no

  json.parent_id department.parent_id
  json.nature_id department.nature_id
  json.committee department.committee
end
