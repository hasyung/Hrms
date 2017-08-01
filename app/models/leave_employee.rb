# t.string :department, index: true #部门名称,各级部门用“-”连接
# t.string :name, index: true #姓名
# t.string :employee_no, index: true #员工号
# t.string :labor_relation, index: true #用工性质
# t.string :file_no, index: true #文件编号
# t.date   :change_date, index: true #变动时间
# t.string :position, index: true #岗位
# t.string :employment_status, index: true #变动性质
# t.string :channel, index: true #通道
# t.string :gender, index: true #性别
# t.date   :birthday, index: true #出生时间
# t.string :identity_no, index: true #身份证号
# t.date   :join_scal_date, index: true #到岗时间
# t.string :remark #备注

class LeaveEmployee < ActiveRecord::Base
  # 暂时将离职原因存在employment_status中，由于历史原因

  def self.create_by_employee(employee, file_no, change_date, reason=nil)
    return if employee.blank? || employee.department.blank? || employee.master_position.blank?
    leave_employee_params = {
      department:          employee.department.full_name,
      name:                employee.name,
      employee_no:         employee.employee_no,
      labor_relation:      employee.labor_relation.try(:display_name),
      file_no:             file_no,
      change_date:         change_date,
      position:            EmployeePosition.full_position_name(employee.employee_positions),
      employment_status:   reason,
      channel:             employee.channel.try(:display_name),
      gender:              employee.gender.try(:display_name),
      birthday:            employee.birthday,
      identity_no:         employee.identity_no,
      join_scal_date:      employee.join_scal_date,
      remark:              '',
      employee_id:         employee.id
    }

    LeaveEmployee.create leave_employee_params
  end

end
