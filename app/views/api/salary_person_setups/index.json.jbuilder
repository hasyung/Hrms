json.salary_person_setups @salary_person_setups do |salary|
  employee = Employee.unscoped.find_by(id: salary.employee_id)
  json.partial! 'api/salary_person_setups/setup', salary: salary, employee: employee
end

json.partial! 'shared/page_basic'