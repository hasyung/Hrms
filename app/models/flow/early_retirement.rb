class Flow::EarlyRetirement < Flow
  include Workflowable

  ATTRIBUTES = [:reason]

  store :form_data, :accessors => ATTRIBUTES
  
  validate :presence_columns

  def presence_columns
    errors.add(:reason, I18n.t("errors.messages.#{self.class.to_s}.reason")) if self.reason.blank?
  end

  def self.initiator(params)
    Employee.joins(:labor_relation).where("employee_labor_relations.display_name='合同' 
      or employee_labor_relations.display_name='合同制' 
      or employee_labor_relations.display_name='合同制（协议）'").map(&:id).include?(params[:receptor_id])
  end
end