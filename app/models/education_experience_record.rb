class EducationExperienceRecord < ActiveRecord::Base
  belongs_to :employee

  belongs_to :education_background, class_name: "CodeTable::EducationBackground", foreign_key: 'education_background_id'
  belongs_to :degree, class_name: "CodeTable::Degree", foreign_key: 'degree_id'
end
