class SocialChangeInfo < ActiveRecord::Base
  belongs_to :employee
  belongs_to :social_person_setup

  default_scope {where("change_date <= '#{Date.current}' and state = '未处理'").order(change_date: 'desc', created_at: 'desc')}

  before_save :update_info, if: -> (info) { info.employee_id_changed? }
  before_save :update_change_date, unless: -> (info) { info.change_date }

  def self.create_by_employee(employee, hash)
    employee.social_change_infos.create(category: hash[:category], indentity_no_was: hash[:indentity_no_was], 
      location_was: hash[:location_was], change_date: hash[:date], salary_reason: hash[:salary_reason])
  end

  private
  def update_info
    self.employee_no = self.employee.employee_no
    self.employee_name = self.employee.name
    self.department_name = self.employee.department.full_name
  end

  def update_change_date
    if self.employee_id_changed?
      self.change_date = Date.current
    end

    if self.employee.social_person_setup
      self.social_person_setup_id = self.employee.social_person_setup.id
    end
  end
end
