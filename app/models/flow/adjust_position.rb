class Flow::AdjustPosition < Flow
  include Workflowable

  ATTRIBUTES = [:to_position_id, :to_department_name, :to_position_name, :channel, :budgeted_staffing, :reason]

  store :form_data, :accessors => ATTRIBUTES

  validate :presence_columns

  before_create :set_form_data

  def self.filter_render_params
    [:to_position_id]
  end

  def presence_columns
    errors.add(:to_position_id, I18n.t("errors.messages.#{self.class.to_s}.to_position_id")) if self.to_position_id.blank?
    errors.add(:reason, I18n.t("errors.messages.#{self.class.to_s}.reason")) if self.reason.blank?
  end

  private
  def set_form_data
    position = Position.find(self.form_data["to_position_id"])
    self.form_data["to_position_name"] = position.name
    self.form_data["to_department_name"] = position.department.full_name
    self.form_data["channel"] = position.channel.try(:display_name)
    self.form_data["budgeted_staffing"] = position.budgeted_staffing
  end
end