class DinnerChange < ActiveRecord::Base
  belongs_to :employee

  default_scope {where("change_date <= '#{Date.current}' and state = '未处理'").order(change_date: 'desc', created_at: 'desc')}

  def self.create_by_employee(employee, hash)
    employee.dinner_changes.create(leave_type: hash[:leave_type], change_date: hash[:change_date] || Date.current, 
      category: hash[:category], start_date: hash[:start_date], end_date: hash[:end_date], point: hash[:point], 
      employee_no: employee.employee_no, employee_name: employee.name)
  end

  def duration_date
    self.start_date.to_s + '至' + (self.end_date.to_s || '无固定')
  end
end
