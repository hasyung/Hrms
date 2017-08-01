json.keep_salaries @keep_salaries do |keep_salary|
  json.partial! 'api/keep_salaries/keep_salary', keep_salary: keep_salary
end

json.partial! 'shared/page_basic'