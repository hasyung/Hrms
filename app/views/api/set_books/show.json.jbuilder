json.set_book_info do
  json.employee_id       @set_book_info.employee_id
  json.bank_no           @set_book_info.bank_no
  json.salary_category   @set_book_info.salary_category
  json.employee_category @set_book_info.employee_category
  json.dep_set_book_no   Department.get_set_book_no(@employee.department)
end
