json.id dinner_person_setup.id
json.employee_id dinner_person_setup.employee_id
json.employee_no dinner_person_setup.employee_no
json.employee_name dinner_person_setup.employee_name
json.shifts_type dinner_person_setup.shifts_type
json.area dinner_person_setup.area
json.card_amount dinner_person_setup.form_data[:card_amount].to_f
json.card_number dinner_person_setup.form_data[:card_number]
json.working_fee dinner_person_setup.form_data[:working_fee].to_f
json.breakfast_number dinner_person_setup.form_data[:breakfast_number]
json.lunch_number dinner_person_setup.form_data[:lunch_number]
json.dinner_number dinner_person_setup.form_data[:dinner_number]
json.change_date dinner_person_setup.change_date
json.is_suspend dinner_person_setup.is_suspend
json.is_mealcard_area dinner_person_setup.is_mealcard_area?
json.deficit_amount dinner_person_setup.deficit_amount.to_f

if dinner_person_setup.employee
  json.department_name dinner_person_setup.employee.department.full_name
  json.position_name dinner_person_setup.employee.master_position.name
  json.location dinner_person_setup.employee.location
end

json.department do
  json.id     dinner_person_setup.employee.department.id
  json.name   dinner_person_setup.employee.department.full_name
  json.grade  dinner_person_setup.employee.department.grade
  json.status dinner_person_setup.employee.department.status || "active"
  json.serial_number dinner_person_setup.employee.department.serial_number
  json.xdepth dinner_person_setup.employee.department.depth

  json.parent_id dinner_person_setup.employee.department.parent_id
  json.nature_id dinner_person_setup.employee.department.nature_id
  json.sort_no   dinner_person_setup.employee.department.sort_no
end
