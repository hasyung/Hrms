class SocialPersonSetup < ActiveRecord::Base
  belongs_to :employee

  default_scope {where(is_delete: false)}

  before_save :update_info, if: -> (social) { social.employee_id_changed?}
  before_save :update_cardinalities, if: -> (social) { social.treatment_cardinality_changed?}

  validates :employee_id, uniqueness: true
  validates_presence_of :social_location

  def self.check_location
    Employee.joins(:social_person_setup).where("social_person_setups.social_location is null")
  end

  def self.check_cardinality
    Employee.joins(:social_person_setup).where("social_person_setups.social_location in (?) 
       and (social_person_setups.pension_cardinality is null or social_person_setups.pension_cardinality = '') 
       and social_person_setups.temp_cardinality is null", Welfare.get_is_annual_locations)
  end

  private
  def update_info
    self.employee_no = self.employee.employee_no
    self.employee_name = self.employee.name
    self.department_name = self.employee.department.full_name
    self.position_name = self.employee.master_position.name
  end

  def update_cardinalities
    self.unemploy_cardinality = self.treatment_cardinality if self.treatment_cardinality
    self.injury_cardinality = self.treatment_cardinality if self.treatment_cardinality
    self.illness_cardinality = self.treatment_cardinality if self.treatment_cardinality
    self.fertility_cardinality = self.treatment_cardinality if self.treatment_cardinality
  end
end
