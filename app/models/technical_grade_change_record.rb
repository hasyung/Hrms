class TechnicalGradeChangeRecord < ActiveRecord::Base
  belongs_to :employee

  def active_change
    return if self.status
    return if self.change_date > Date.today

    ActiveRecord::Base.transaction do
      self.employee.salary_person_setup.update(
        technical_grade: self.technical_grade
      )
      self.update(status: true)
    end
  end
end
