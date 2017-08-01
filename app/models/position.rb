# == Schema Information
#
# Table name: positions
#
#  id                 :integer          not null, primary key
#  pinyin_name        :string(255)
#  pinyin_index       :string(255)
#  name               :string(255)
#  budgeted_staffing  :integer
#  oa_file_no         :string(255)
#  post_type          :string(255)
#  remark             :string(255)
#  department_id      :integer
#  channel_id         :integer
#  schedule_id        :integer
#  category_id        :integer
#  position_nature_id :integer
#  employees_count    :integer          default("0")
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
#

class Position < ActiveRecord::Base
  audited except: [
    :sort_no, :pinyin_name, :pinyin_index, :employees_count, :is_confirmed,
    :is_delete, :temperature_amount, :communicate_allowance, :cold_subsidy_type
  ]
  include Pinyinable
  include Snapshotable
  include Connectable

  belongs_to :department
  belongs_to :channel, class_name: "CodeTable::Channel"
  belongs_to :schedule, class_name: "Schedule"
  belongs_to :category, class_name: "CodeTable::Category"
  belongs_to :position_nature, class_name: "CodeTable::PositionNature", foreign_key: 'position_nature_id'

  has_many :employee_positions
  has_many :employees, through: :employee_positions
  has_many :master_employees, -> { where('employee_positions.sort_index = 0') }, through: :employee_positions, source: :employee

  has_one :specification, :dependent => :destroy

  default_scope {where(is_delete: false)}
  scope :not_confirmed, -> { where(is_confirmed: false) }

  accepts_nested_attributes_for :specification, limit: 1

  validate :presence_columns

  def presence_columns
    errors.add(:name, I18n.t("errors.messages.#{self.class.to_s}.name"))                           if self.name.blank?
    errors.add(:budgeted_staffing, I18n.t("errors.messages.#{self.class.to_s}.budgeted_staffing")) if self.budgeted_staffing.blank?
    errors.add(:oa_file_no, I18n.t("errors.messages.#{self.class.to_s}.oa_file_no"))               if self.oa_file_no.blank?
    errors.add(:department_id, I18n.t("errors.messages.#{self.class.to_s}.department_id"))         if self.department_id.blank?
  end

  def staffing
    self.employees_count
  end

  def self.total_budgeted_staffing
    self.all.map(&:budgeted_staffing).inject(&:+) || 0
  end

  def self.total_staffing
    self.all.map(&:staffing).inject(&:+) || 0
  end

  def self.part_time_staffing
    EmployeePosition.part_time_staffing.where('employee_positions.position_id in (?)',  self.all.map(&:id)).count
  end

  def self.can_destroy?
    # 当它们的users_count都等于0n那么它们可以删除
    all.map(&:staffing).inject(&:+) == 0
  end

  def self.adjust(params)
    where(id: params[:position_ids]).each do |position|
      department = Department.find params[:department_id]
      #岗位调整2步处理
      # 1. 首先修改岗位的部门ID, 修改排序sort_no值
      sort_no = department.positions.present? ? department.positions.map(&:sort_no).max + 1 : 1
      position.update!(department_id: department.id, sort_no: sort_no)

      # 2. 更新部门下对应的岗位的员工信息表的主岗的department_id字段值
      employees = position.master_employees
      position.master_employees.update_all(department_id: department.id)

      # 3. 更新该变动的人员的考勤信息
      AttendanceSummary.update_summary(employees)
    end
  end

  def self.query(query_params)
    query_params.inject(self) do |positions ,(key, value)|
      positions = positions.where(serialize_condition(key, value))
      positions
    end
  end

  def leader_position?
    ["LingDao", "GanBu"].include?(self.category.try(:key))
  end

  def snapshot_attributes
    self.attributes.merge(
      "staffing" => self.staffing,
      "channel" => self.channel.try(:attributes),
      "category" => self.category.try(:attributes),
      "nature" => self.position_nature.try(:attributes),
      "schedule" => self.schedule.try(:attributes),
      "specification" => self.specification.try(:attributes),
      "former_leaders" => self.former_leader_snapshot
    )
  end

  def former_leader_snapshot
    if self.leader_position?
      EmployeePosition.includes(:employee).unscoped.where.not(end_date: nil).where(position_id: self.id).inject([]) do |former_leaders, employee_position|
        former_leaders << {
          id: employee_position.employee.id,
          employee_no: employee_position.employee.employee_no,
          start_date: employee_position.start_date,
          end_date: employee_position.end_date,
          remark: employee_position.remark,
          employee_name: employee_position.employee.name
        }
        former_leaders
      end
    else
      []
    end
  end

  def fix_sort_no
    sort_no = self.department.positions.empty? ? 1 : self.department.positions.maximum(:sort_no) + 1

    self.sort_no = sort_no
    self.save if self.id.present?
  end

  private

  def self.serialize_condition(key, value)
    Setting.query_rule.position.sql.send(key).gsub('?', value.to_s)
  end

  class << self
    def sort(current_id, target_id)
      current_item     = self.find(current_id)
      current_place = current_item.sort_no
      target_item      = self.find(target_id)
      target_place  = target_item.sort_no

      if current_place > target_place
        # 排序上升
        self.where("department_id = ? and sort_no >= ? and sort_no < ?",\
                   target_item.department_id,\
                   target_place,\
                   current_place
                  ).update_all("sort_no = sort_no + 1")
      else
        # 排序下降
        self.where("department_id = ? and sort_no > ? and sort_no <= ?",\
                   current_item.department_id,\
                   current_place,\
                   target_place
                  ).update_all("sort_no = sort_no - 1")
      end

      #更新自己
      current_item.update(sort_no: target_place)
    end
  end
end
