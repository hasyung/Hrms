class Flow::EmployeeLeaveJob < Flow
  include Workflowable

  ATTRIBUTES = [:reason, :flow_id]

  store :form_data, :accessors => ATTRIBUTES
  validate :presence_columns

  def presence_columns
    errors.add(:reason, I18n.t("errors.messages.#{self.class.to_s}.reason")) if self.reason.blank?
  end

  before_create do
    file_manager_ids = self.class.file_manager(self.receptor.department_id)
    self.reviewer_ids = file_manager_ids

    Flow.find(self.flow_id).update(leave_job_state: true) if self.flow_id
  end

  def self.initiator(params)
    self.hr_labor_relation_member.include?(params[:sponsor_id])
  end

  def active_workflow(validate = true)
    hash = {employee_id: self.receptor_id, file_no: "无文件编号", reason: self.reason}
    Publisher.broadcast_event('EMPLOYEE_LEAVE', hash)
    ChangeRecord.save_record('employee_outgo', Employee.unscoped{ self.receptor }).send_notification if self.reason == '工作调动'
    ChangeRecordWeb.save_record('employee_outgo', Employee.unscoped{ self.receptor }).send_notification if self.reason == '工作调动'
    self.update(workflow_state: 'actived')
  end

  def self.filter_render_params
    [:flow_id, :leave_job_state]
  end
end
