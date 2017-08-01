namespace :fix do
  desc "fix nation data"
  task nation_repair: :environment  do
    Employee.find_each do |employee|
      if employee.nation_id
        nation = CodeTable::Nation.find(employee.nation_id).try(:display_name)
        employee.update(nation: nation)
      else
        employee.update(nation: '汉族')
      end
    end
  end
end