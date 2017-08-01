namespace :fix do
  desc "修改员工的第一条工作经历的开始时间"

  task work_experience: :environment do
    employee_id = Employee.find_by(employee_no: '000131')

    Employee::WorkExperience
      .where("employee_id != ? AND employee_category not in (?)", employee_id, ["干部", "领导"])
      .order("date(start_date)")
      .to_a.uniq(&:employee_id)
      .each do |work_experience|
        employee = work_experience.employee

        next unless employee && employee.join_scal_date
        work_experience.update(start_date: employee.join_scal_date)
      end
  end

  desc 'fix start_work_date'
  task fix_start_work_date: :environment do
    Employee.unscoped.where("start_work_date is NULL").each do |emp|
      emp.update(start_work_date: emp.join_scal_date)
    end
  end
end
