json.basic_salaries @basic_salaries do |salary|
  json.partial! 'api/basic_salaries/basic_salary', salary: salary
end

json.partial! 'shared/page_basic'