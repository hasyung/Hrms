class Flow::Dismiss < Flow
  include Workflowable
  ATTRIBUTES = [:reason, :leave_job_state]

  store :form_data, :accessors => ATTRIBUTES

  validate :presence_columns

  def presence_columns
    errors.add(:reason, I18n.t("errors.messages.#{self.class.to_s}.reason")) if self.reason.blank?
  end

  before_create do 
    self.leave_job_state = false
    true
  end

  after_create :start_social_change_info
  after_create :annuity_status_change
  after_save :stop_social_change_info

  # 发起人为部门HR
  def self.initiator(params)
    department_hr = self.department_hr(Employee.find(params[:receptor_id]).department_id)

    department_hr.include?(params[:sponsor_id])
  end

  def self.filter_render_params
    [:leave_job_state]
  end

  private
  def start_social_change_info
    social_hash = {employee_id: self.receptor_id, category: '停薪调', salary_reason: '辞退'}
    Publisher.broadcast_event('SOCIAL_CHANGE_INFO', social_hash)

    salary_hash = {employee_id: self.receptor_id, category: '停薪调', reason: '辞退'}
    Publisher.broadcast_event('SALARY_CHANGE', salary_hash)
  end

  def stop_social_change_info
    if(self.workflow_state_changed? && (self.workflow_state == 'rejected' || self.workflow_state == 'repeal'))
      social_hash = {employee_id: self.receptor_id, category: '停薪调停止', salary_reason: '辞退'}
      Publisher.broadcast_event('SOCIAL_CHANGE_INFO', social_hash)

      salary_hash = {employee_id: self.receptor_id, category: '停薪调停止', reason: '辞退'}
      Publisher.broadcast_event('SALARY_CHANGE', salary_hash)
    end
  end

  def annuity_status_change
      hash = {employee_id: self.receptor_id}
      Publisher.broadcast_event("EMPLOYEE_LAUNCH_FIRE", hash)
  end
end
