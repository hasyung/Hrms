json.performance_salaries @performance_salaries do |performance_salary|
  json.partial! 'api/performance_salaries/performance_salary', performance_salary: performance_salary
end

json.partial! 'shared/page_basic'