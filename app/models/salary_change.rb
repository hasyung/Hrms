class SalaryChange < ActiveRecord::Base
  belongs_to :employee
  belongs_to :salary_person_setup
  belongs_to :position_change_record

  has_one :salary_setup_cache

  default_scope {where("change_date <= '#{Date.current}' and state = '未处理'").order(change_date: 'desc', created_at: 'desc')}

  before_save :update_info, if: -> (info) { info.employee_id_changed? }
  before_save :update_salary_person_setup

  def self.create_by_employee(employee, hash)
    employee.salary_changes.create(category: hash[:category], change_date: hash[:date] || Date.current,
      position_name_history: hash[:position_name_history], reason: hash[:reason], 
      prev_channel_id: hash[:prev_channel_id], position_change_record_id: hash[:position_change_record_id])
  end

  private
  def update_info
    self.employee_no     = self.employee.employee_no
    self.employee_name   = self.employee.name
    self.department_name = self.employee.department.full_name
    self.position_name   = self.employee.master_position.try(:name)
  end

  def update_salary_person_setup
    if self.employee.salary_person_setup
      self.salary_person_setup_id = self.employee.salary_person_setup.id
    end
  end
end
