# == Schema Information
#
# Table name: employee_search_conditions
#
#  id          :integer          not null, primary key
#  employee_id :integer          not null
#  name        :string(255)
#  code        :string(255)
#  condition   :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_employee_search_conditions_on_code         (code)
#  index_employee_search_conditions_on_employee_id  (employee_id)
#  index_employee_search_conditions_on_name         (name)
#

class Employee::SearchCondition < ActiveRecord::Base

  belongs_to :employee

  validates_uniqueness_of :employee, scope: [:employee_id, :name, :code]

  validate :presence_columns

  def presence_columns
    errors.add(:employee_id, I18n.t("errors.messages.#{self.class.to_s}.employee_id")) if self.employee_id.blank?
    errors.add(:condition, I18n.t("errors.messages.#{self.class.to_s}.condition")) if self.condition.blank?
  end
end
