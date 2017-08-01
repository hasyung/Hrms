# == Schema Information
#
# Table name: employee_positions
#
#  id          :integer          not null, primary key
#  employee_id :integer
#  position_id :integer
#  sort_index  :integer          default("0")
#  start_date  :date
#  end_date    :date
#  remark      :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class EmployeePosition < ActiveRecord::Base
  belongs_to :employee
  belongs_to :position

  after_save :update_employees_count
  after_destroy :decrease_employees_count, if: ->(cord){ cord[:end_date].blank? }

  default_scope { where(end_date: nil) }
  scope :part_time_staffing, -> {where.not(sort_index: 0)}

  before_create{ self.start_date = Date.today }
  # after_create :generate_work_experience

  audited associated_with: :employee, except: [ :sort_index, :employee_id, :remark ]

  # validates_inclusion_of :category, in: %w(主职 兼职 代理)
  #validates_uniqueness_of :category, if: :primary_position_present?

  def change_position(end_date = nil, ignore_audit = 0)
    employee = Employee.unscoped.find(self.employee_id)
    position = Position.find(self.position_id)
    dep_name = position.department.full_name
    pos_name = position.name + "(#{category})"
    experiences = employee.work_experiences.where(company: '四川航空', department: dep_name, position: pos_name)

    if ignore_audit == 0
      if experiences.empty?
        employee.work_experiences.create!(company: '四川航空', department: dep_name, position: pos_name, start_date: self.created_at.to_date, end_date: (end_date || Date.today), category: "after")
      else
        experiences.first.update!(end_date: (end_date || Date.today))
      end
    end

    self.end_date = (end_date || Date.today)

    if ignore_audit == 1
      self.save_without_auditing
    else
      self.save!
    end
  end

  def full_name
    pos = self.position
    return pos.name if self.category == '主职'
    return "#{pos.name}(兼)" if self.category == '兼职'
    return "#{pos.name}(代)" if self.category == '代理'
    return "#{pos.name}(临时主持)" if self.category == '临时主持'
  end

  def self.full_position_name(array)
    # self.ordered.inject([]) do |position_names, emp_pos|
    # 需求变更: 按照界面上显示的(sort_index)来排序
    array.inject([]) do |position_names, emp_pos|
      position_names << emp_pos.full_name
      position_names
    end.join('/')
  end

  def self.ordered
    categories = %w(主职 兼职 代理 临时主持)
    self.all.sort{|a, b| categories.index(a.category) <=> categories.index(b.category)}
  end

  def generate_work_experience(start_date = nil, ignore_audit = 0)
    employee = Employee.find(self.employee_id)
    position = Position.find(self.position_id)

    work_experience = employee.work_experiences.new(
      start_date: start_date || Date.today,
      company: '四川航空',
      department: position.department.full_name,
      position: position.name + "(#{self.category})",
      end_date: "至今",
      category: "after"
    )
    ignore_audit == 0 ? work_experience.save : work_experience.save_without_auditing
  end

  private
  def update_employees_count
    if self.new_record?
      self.position.update(employees_count: self.position.employees_count + 1)
    else
      if self.end_date_was.blank? && self.end_date.present?
        self.position.update(employees_count: self.position.employees_count - 1) if self.position.employees_count > 0
      end
      if self.position_id_changed? && self.end_date.blank?
        position = Position.find_by(id: position_id_was)
        position.update(employees_count: position.employees_count - 1) if position.present? && position.employees_count > 0
        self.position.update(employees_count: self.position.employees_count + 1)
      end
    end
  end

  def decrease_employees_count
    self.position.update(employees_count: self.position.employees_count - 1) if self.position.present? && self.position.employees_count > 0
  end

  def primary_position_present?
    return false if self.category != '主职' || self.end_date != nil
    return false unless self.position_id_changed?

    employee_positions = EmployeePosition.where(category: '主职', employee_id: self.employee_id)
    (employee_positions.count > 0) ? true : false
  end
end
