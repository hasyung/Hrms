json.keep_salary do
  json.partial! 'api/keep_salaries/keep_salary', keep_salary: @keep_salary
end