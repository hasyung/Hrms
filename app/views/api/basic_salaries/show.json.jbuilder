json.basic_salary do
  json.partial! 'api/basic_salaries/basic_salary', salary: @basic_salary
end