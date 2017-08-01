class Flow::RenewContract < Flow
  include Workflowable

  ATTRIBUTES = [:start_date, :duration, :duration_date, :last_duration_date]

  store :form_data, :accessors => ATTRIBUTES
  validate :presence_columns

  def presence_columns
    errors.add(:start_date, I18n.t("errors.messages.#{self.class.to_s}.start_date")) if self.start_date.blank?
  end

  before_create do
    self.duration_date = self.start_date.to_date.to_s + "至" + end_date
    self.last_duration_date = self.receptor.last_contact_duration
  end

  def self.initiator(params)
    self.hr_labor_relation_member.include?(params[:sponsor_id])
  end

  def end_date
    return '无固定' if self.duration.blank?
    
    s_date = self.start_date.to_date
    s_date.change(year: (s_date.year + self.duration.to_i)).to_s
  end

  def self.filter_render_params
    [:start_date, :duration]
  end
end