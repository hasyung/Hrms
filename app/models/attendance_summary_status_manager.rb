class AttendanceSummaryStatusManager < ActiveRecord::Base
  has_many :attendance_summaries
  belongs_to :department

  def department_status
    return "未确认完成" if (self.department_hr_checked == false && self.hr_department_leader_checked == false)
    return "已确认完成" if self.hr_department_leader_checked == true
    return "部门已审批" if (self.department_leader_checked == true && self.hr_department_leader_checked == false)
  end

  def company_status
    self.department_leader_checked ? "领导已审核" : "领导未审核"
  end

  def department_hr_check(operator, check_hr=true, department_id = FlowRelation.get_deps_department_hr(operator).first)
    self.hr_name = operator.name
    self.hr_confirmed_at = DateTime.now
    AttendanceSummary.special_state_days_to_summaries("#{self.summary_date}-01", department_id, check_hr, self.department_id)
    self.update(department_hr_checked: true)
  end

  def department_leader_check(operator, opinion)
    self.department_leader_name = operator.name
    self.department_leader_opinion = opinion
    self.department_leader_confirmed_at = DateTime.now
    self.update(department_leader_checked: true)
  end

  def hr_department_leader_check(operator, opinion)
    self.hr_leader_name = operator.name
    self.hr_department_leader_opinion = opinion
    self.hr_leader_confirmed_at = DateTime.now
    self.update(hr_department_leader_checked: true)
  end

  def hr_labor_relation_member_check(operator, opinion)
    self.hr_labor_relation_member_name = operator.name
    self.hr_labor_relation_member_opinion = opinion
    self.hr_labor_relation_member_confirmed_at = DateTime.now
    self.update(hr_labor_relation_member_checked: true)
  end

  def self.hr_department_leader_checked?
    self.first.hr_department_leader_checked
  end

  def update_department_name
    self.update department_name: self.department.full_name if self.department.try(:full_name)
  end

  def administrator_check
    self.update(hr_department_leader_checked: true)
  end
end
