class EarlyRetireEmployee < ActiveRecord::Base
  belongs_to :employee
  
  def self.create_by_employee(employee, file_no, change_date, reason=nil)
    return if employee.blank? || employee.department.blank? || employee.master_position.blank?

    early_retire_employee_params = {
      department: employee.department.full_name,
      name: employee.name,
      employee_no: employee.employee_no,
      labor_relation: employee.labor_relation.try(:display_name),
      file_no: file_no,
      change_date: change_date,
      position: EmployeePosition.full_position_name(employee.employee_positions),
      channel: employee.channel.try(:display_name),
      gender: employee.gender.try(:display_name),
      birthday: employee.birthday,
      identity_no: employee.identity_no,
      join_scal_date: employee.join_scal_date,
      remark: '',
      employee_id: employee.id
    }

    EarlyRetireEmployee.create(early_retire_employee_params)
  end
end
