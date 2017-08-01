class Flow::Retirement < Flow
  include Workflowable

  after_save :annuity_status_change

  ATTRIBUTES = [:leave_job_state, :retirement_date]
  store :form_data, :accessors => ATTRIBUTES

  validate :presence_columns

  def presence_columns
    return errors.add(:retirement_date, I18n.t("errors.messages.#{self.class.to_s}.retirement_date")) if self.retirement_date.blank?
    if self.retirement_date.to_date < Date.today
      errors.add(:retirement_date, "退休日期必须大于当前日期")
    end
  end

  def self.initiator(params)
    self.hr_labor_relation_member.include?(params[:sponsor_id])
  end

  before_create do
    self.leave_job_state = false
    true
  end

  def self.filter_render_params
    [:leave_job_state]
  end

  def active_workflow(validate = true)
    hash = {employee_id: self.receptor_id, category: '退休', date: self.retirement_date}
    Publisher.broadcast_event('SOCIAL_CHANGE_INFO', hash)

    self.receptor.update(retirement_date: self.retirement_date)
    ChangeRecord.save_record("employee_retire", Employee.unscoped{ self.receptor }).send_notification
    ChangeRecordWeb.save_record("employee_retire", Employee.unscoped{ self.receptor }).send_notification
    self.update(workflow_state: 'actived')
  end

  private
  def annuity_status_change
    if ["accepted", "actived"].include?(self.workflow_state)
      hash = {employee_id: self.receptor_id}
      Publisher.broadcast_event("EMPLOYEE_RETIREMENT", hash)
    end
  end
end
