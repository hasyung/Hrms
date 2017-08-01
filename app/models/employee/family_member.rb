# == Schema Information
#
# Table name: employee_family_members
#
#  id                   :integer          not null, primary key
#  name                 :string(255)
#  native_place         :string(255)
#  birthday             :date
#  start_work_date      :date
#  married_date         :date
#  gender               :string(255)
#  nation               :string(255)
#  position             :string(255)
#  company              :string(255)
#  mobile               :string(255)
#  identity_no          :string(255)
#  residence_booklet    :string(255)
#  political_status     :string(255)
#  education_background :string(255)
#  relation_type        :string(255)
#  relation             :string(255)
#  employee_id          :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#

# 家庭成员
class Employee::FamilyMember < ActiveRecord::Base
  belongs_to :employee

  audited associated_with: :employee, except: [ :employee_id ]

  validate :presence_columns

  def presence_columns
    errors.add(:name, I18n.t("errors.messages.#{self.class.to_s}.name")) if self.name.blank?
    errors.add(:relation_type, I18n.t("errors.messages.#{self.class.to_s}.relation_type")) if self.relation_type.blank?
    errors.add(:gender, I18n.t("errors.messages.#{self.class.to_s}.gender")) if self.gender.blank?
  end
end
