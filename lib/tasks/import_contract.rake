namespace :import do
  task contract: :environment do
    Contract.transaction do
      CSV.foreach("#{Rails.root}/public/contract.csv") do |row|
        cols = row[0].split(' ')

        puts "==="
        puts cols.inspect

        contract_attr = {
          department_name: cols[0],
          position_name: cols[1],
          employee_name: cols[2],
          apply_type: cols[3],
          change_flag: cols[4],
          contract_no: cols[5],
          due_time: cols[6],
          start_date: cols[7],
          end_date: cols[8],
          join_date: cols[9],
          status: cols[10],
          employee_no: cols[5]
        }
        employee = Employee.find_by(employee_no: contract_attr[:employee_no], name: contract_attr[:employee_name])

        contract_attr[:is_unfix] = true if contract_attr[:due_time] == "无固定"
        if employee
          contract_attr[:employee_id] = employee.id 
          contract_attr[:employee_exists] = true
        else
          contract_attr[:employee_id] = 0
          contract_attr[:employee_exists] = false
        end

        Contract.create!(contract_attr)
      end
    end
  end

  task fix_contract_employ_id: :environment do
    Contract.transaction do
      Contract.unscoped.all.each do |item|
        employee = Employee.unscoped.where(employee_no: item.employee_no, name: item.employee_name)
        if employee.present?
          item.update(employee_id: employee.first.id)
        else
          item.update(employee_id: 0)
        end
      end
    end
  end
end
