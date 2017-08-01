class Punishment < ActiveRecord::Base
  belongs_to :employee

  before_save :update_info, if: -> (punishment) { punishment.employee_id_changed?}

  default_scope {order(created_at: 'desc')}

  validate :presence_columns

  def presence_columns
    errors.add(:category, I18n.t("errors.messages.#{self.class.to_s}.category")) if self.genre == '处分' && self.category.blank?
    errors.add(:desc, I18n.t("errors.messages.#{self.class.to_s}.desc")) if self.desc.blank?
    errors.add(:start_date, I18n.t("errors.messages.#{self.class.to_s}.start_date")) if self.genre == '处分' && self.end_date.present? && self.start_date.blank?
    errors.add(:end_date, I18n.t("errors.messages.#{self.class.to_s}.end_date")) if self.genre == '处分' && self.start_date.present? && self.end_date.blank?
    if self.genre == '处分' && self.start_date && self.end_date && self.start_date > self.end_date
      errors.add(:start_date, I18n.t("errors.messages.#{self.class.to_s}.start_date_too_large"))
    end

    errors.add(:reward_date, I18n.t("errors.messages.#{self.class.to_s}.reward_date")) if self.genre == '奖励' && self.reward_date.blank?
  end

  private
  def update_info
    self.employee_name = self.employee.name
  end
end
