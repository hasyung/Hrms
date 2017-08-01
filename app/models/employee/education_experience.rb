# == Schema Information
#
# Table name: employee_education_experiences
#
#  id                      :integer          not null, primary key
#  school                  :string(255)
#  major                   :string(255)
#  admission_date          :string(255)
#  graduation_date         :string(255)
#  education_background_id :integer
#  education_nature_id     :integer
#  degree_id               :integer
#  witness                 :string(255)
#  category                :string(255)      default("before")
#  employee_id             :integer
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#

# 教育经历
class Employee::EducationExperience < ActiveRecord::Base
  belongs_to :employee, class_name: 'Employee', inverse_of: :education_experiences

  belongs_to :education_background, class_name: "CodeTable::EducationBackground", foreign_key: 'education_background_id'
  belongs_to :degree, class_name: "CodeTable::Degree", foreign_key: 'degree_id'
  belongs_to :education_nature, class_name: "CodeTable::EducationNature", foreign_key: 'education_nature_id'

  before_save :update_date_columns

  audited associated_with: :employee

  validate :presence_columns
  validate :compare_admission_and_graduation_date

  def presence_columns
    errors.add(:school, I18n.t("errors.messages.#{self.class.to_s}.school")) if self.school.blank?
    errors.add(:major, I18n.t("errors.messages.#{self.class.to_s}.major")) if self.major.blank?
  end

  def compare_admission_and_graduation_date
    if self.admission_date && self.graduation_date
      admission_date = self.admission_date.to_date
      graduation_date = self.graduation_date.to_date

      errors.add(:graduation_date, "毕业时间必须大于入学时间") if admission_date > graduation_date
    end
  end

  private
  def update_date_columns
    self.admission_date = self.admission_date.gsub('.', '-').at(0..9) if self.admission_date
    self.graduation_date = self.graduation_date.gsub('.', '-').at(0..9) if self.graduation_date
  end
end
