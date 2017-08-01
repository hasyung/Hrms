#员工彻底离开，无法再使用系统
Subscriber.subscribe("EMPLOYEE_LEAVE") do |event|
  #{employee_id: '', file_no: '', reason: '', date: ''}
  hash = event.payload

  employee = Employee.unscoped.find_by(id: hash[:employee_id])
  raise ActiveRecord::RecordNotFound if employee.blank? || hash[:reason].blank? || hash[:file_no].blank?

  #添加离职信息
  LeaveEmployee.create_by_employee(employee, hash[:file_no], hash[:date], hash[:reason])

  #将社保个人设置和薪酬个人设置置为软删除
  employee.social_person_setup.update(is_delete: true) if employee.social_person_setup
  employee.salary_person_setup.update(is_stop: true) if employee.salary_person_setup

  #重置密码/is_delete:true/为人岗关系的end_date赋值
  employee.leave_company(hash[:reason], hash[:date])

  #修改合同人员状态
  Contract.update_status(employee, hash[:reason])

  #产生异动记录
  leave_type = {
    "工作调动" => "employee_outgo",
    "辞职" => "employee_resign",
    "辞退" => "employee_fire",
    "劳动关系终止" => "employee_resign",
    "退休" => "employee_retire"
  }[hash[:reason]]
  ChangeRecord.save_record(leave_type, Employee.unscoped{ employee }).send_notification if leave_type
  ChangeRecordWeb.save_record(leave_type, Employee.unscoped{ employee }).send_notification if leave_type
end

# 员工退养，还可以登录系统
Subscriber.subscribe("EMPLOYEE_EARLY_RETIRE") do |event|
  hash = event.payload

  employee = Employee.find_by(id: hash[:employee_id])
  raise ActiveRecord::RecordNotFound if employee.blank? || hash[:file_no].blank?

  EarlyRetireEmployee.create_by_employee(employee, hash[:file_no], hash[:date])

  employee.early_retire(hash[:date])

  #产生异动记录
  ChangeRecord.save_record("employee_early_retire", Employee.unscoped{ employee }).send_notification
  ChangeRecordWeb.save_record("employee_early_retire", Employee.unscoped{ employee }).send_notification if leave_type
end

#当员工做了与社保信息相关的操作时，记录变动信息
Subscriber.subscribe("SOCIAL_CHANGE_INFO") do |event|
  #{employee_id: '', category: '', date: '', indentity_no_was: '', location_was: '', salary_reason: ''}
  hash = event.payload

  employee = Employee.unscoped.find hash[:employee_id]

  #添加社保变动信息
  SocialChangeInfo.create_by_employee(employee, hash)
  #添加年金备注记录
  employee.annuity_notes.create(category: "identity_no")

  employee.update(is_stop_salary: true) if hash[:category] == '停薪调'
  employee.update(is_stop_salary: false) if hash[:category] == '停薪调停止'
end

#当员工做了与薪酬信息相关的操作时，记录变动信息
Subscriber.subscribe("SALARY_CHANGE") do |event|
  #{employee_id: '', category: '', date: '', position_name_history: '', reason: '', prev_channel_id: '', position_change_record_id: ''}
  hash = event.payload

  employee = Employee.unscoped.find hash[:employee_id]

  #添加薪酬变动信息
  SalaryChange.create_by_employee(employee, hash)

  employee.update(is_stop_salary: true) if hash[:category] == '停薪调'
  employee.update(is_stop_salary: false) if hash[:category] == '停薪调停止'
end

Subscriber.subscribe("EMPLOYEE_LAUNCH_LEAVE") do |event|
  #{employee_id: '', date: ''}
  hash = event.payload

  employee = Employee.find hash[:employee_id]

  message = "员工辞职"
  AnnuityApply.create_apply(employee, message)
end

Subscriber.subscribe("EMPLOYEE_LAUNCH_FIRE") do |event|
  #{employee_id: '', date: ''}
  hash = event.payload

  employee = Employee.find hash[:employee_id]

  message = "员工辞退"
  AnnuityApply.create_apply(employee, message)
end

Subscriber.subscribe("EMPLOYEE_RETIREMENT") do |event|
  #{employee_id: '', date: ''}
  hash = event.payload

  employee = Employee.find hash[:employee_id]

  message = "员工退休"
  AnnuityApply.create_apply(employee, message)
end

Subscriber.subscribe("DINNER_CHANGE") do |event|
  #{employee_id: '', category: '', change_date: '', leave_type: '', start_date: '', end_date: '', point: ''}
  hash = event.payload
  employee = Employee.find hash[:employee_id]

  #添加工作餐变动信息
  DinnerChange.create_by_employee(employee, hash)
end
