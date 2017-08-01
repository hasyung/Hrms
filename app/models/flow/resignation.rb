class Flow::Resignation < Flow
  include Workflowable

  ATTRIBUTES = [:reason, :leave_date, :leave_job_state]

  store :form_data, :accessors => ATTRIBUTES
  validate :check_leave_date
  validate :check_attachments

  validate :presence_columns

  def presence_columns
    errors.add(:reason, I18n.t("errors.messages.#{self.class.to_s}.reason")) if self.reason.blank?
    errors.add(:leave_date, I18n.t("errors.messages.#{self.class.to_s}.leave_date")) if self.leave_date.blank?
  end

  before_create do 
    self.leave_job_state = false
    true
  end

  before_create :start_social_change_info
  after_create :annuity_status_change
  before_save :stop_social_change_info

  def self.initiator(params)
    department_hr = self.department_hr(Employee.find(params[:receptor_id]).department_id)

    params[:receptor_id] == params[:sponsor_id] || department_hr.include?(params[:sponsor_id])
  end
  
  def self.filter_render_params
    [:leave_job_state]
  end

  private
  def check_leave_date
    return if leave_date.blank?
    if leave_date.to_date < Date.today && workflow_state != 'repeal'
      errors.add(:leave_date, "离职时间必须大于当前时间")
    end
  end

  def check_attachments
    if self.sponsor_id != self.receptor_id && self.flow_attachments.size == 0
      errors.add(:attachment_ids, "必须上传附件")
    end
  end

  def start_social_change_info
    social_hash = {employee_id: self.receptor_id, category: '停薪调', salary_reason: '辞职'}
    Publisher.broadcast_event('SOCIAL_CHANGE_INFO', social_hash)

    salary_hash = {employee_id: self.receptor_id, category: '停薪调', reason: '辞职'}
    Publisher.broadcast_event('SALARY_CHANGE', salary_hash)
  end

  def stop_social_change_info
    if(self.workflow_state_changed? && (self.workflow_state == 'rejected' || self.workflow_state == 'repeal'))
      social_hash = {employee_id: self.receptor_id, category: '停薪调停止', salary_reason: '辞职'}
      Publisher.broadcast_event('SOCIAL_CHANGE_INFO', social_hash)

      salary_hash = {employee_id: self.receptor_id, category: '停薪调停止', reason: '辞职'}
      Publisher.broadcast_event('SALARY_CHANGE', salary_hash)
    end
  end

  def annuity_status_change
      hash = {employee_id: self.receptor_id}
      Publisher.broadcast_event("EMPLOYEE_LAUNCH_LEAVE", hash)
  end
end
