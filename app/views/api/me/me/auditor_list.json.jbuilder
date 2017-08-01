json.employees @employees do |employee|
  json.id employee.id
  json.name employee.name
  
  json.department do 
    json.name employee.department.full_name
  end

  json.position do 
    json.name employee.master_position.name
  end
end