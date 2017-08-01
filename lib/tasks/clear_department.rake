namespace :clear do
  desc 'clear departments where parent no exists'
  task departments: :environment do
    Department.where.not(serial_number: '000').each do |dep|
      dep.destroy unless dep.parent
      puts "已删除机构：#{dep.name}"
    end
  end

  desc 'clear code_table about employment_status with 离职员工'
  task employment_status: :environment do
    status = Employee::EmploymentStatus.find_by(display_name: '离职员工')
    if status
      status.destroy
      puts "已删除用工状态-离职员工"
    else
      puts "没有找到用工状态-离职员工"
    end
  end
end
