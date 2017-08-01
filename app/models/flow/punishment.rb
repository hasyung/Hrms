class Flow::Punishment < Flow
  include Workflowable

  ATTRIBUTES = [:reason]

  store :form_data, :accessors => ATTRIBUTES
  validate :presence_columns

  def presence_columns
    errors.add(:reason, I18n.t("errors.messages.#{self.class.to_s}.reason")) if self.reason.blank?
  end 

  # 发起人为部门HR
  def self.initiator(params)
    department_hr = self.department_hr(Employee.find(params[:receptor_id]).department_id)

    department_hr.include?(params[:sponsor_id])
  end 
end