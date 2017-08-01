class AnnuityApply < ActiveRecord::Base
  belongs_to :employee

  def handle(status)
    return if self.status
    self.send("handle_#{status}")
    self.update(status: true) #标记为处理过
  end

  def handle_true
    case self.apply_category
    when "员工退休"
      self.employee.exit_annuity
      self.employee.annuity_notes.create(category: "retirement")
    when "员工辞职"
      self.employee.exit_annuity
      self.employee.annuity_notes.create(category: "fire")
    when "员工辞退"
      self.employee.exit_annuity
      self.employee.annuity_notes.create(category: "fire")
    when "申请加入"
      self.employee.join_annuity
      self.employee.annuity_notes.create(category: "join")
    when "申请退出"
      self.employee.join_annuity
    end
  end

  def handle_false
    case self.apply_category
    when "员工退休"
      self.employee.annuity_notes.create(category: "retirement")
    when "员工辞职"
      self.employee.annuity_notes.create(category: "fire")
    when "员工辞退"
      self.employee.annuity_notes.create(category: "fire")
    when "申请退出"
      self.employee.annuity_notes.create(category: "stop")
    end
    self.employee.exit_annuity
  end

  class << self
    def create_apply(employee, message)
      employee.annuity_applies.find_or_create_by(
        employee_name: employee.name,
        employee_no: employee.employee_no,
        department_name: employee.department.full_name,
        apply_category: message,
        status: false
      ) if employee.is_contract_regulation? and employee.annuity_account_no.present?
    end
  end
end
