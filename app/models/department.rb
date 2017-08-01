# == Schema Information
#
# Table name: departments
#
#  id              :integer          not null, primary key
#  name            :string(255)
#  pinyin_name     :string(255)
#  pinyin_index    :string(255)
#  serial_number   :string(255)
#  depth           :integer
#  childrens_count :integer          default("0")
#  grade_id        :integer          default("0")
#  nature_id       :integer
#  parent_id       :integer
#  childrens_index :integer          default("0")
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class Department < ActiveRecord::Base
  include Snapshotable
  include Connectable
  include Departmentable
  include Pinyinable

  attr_accessor :status

  scope :descendant_of, -> (serial_number) { where("serial_number like ?", "%#{serial_number}%") }
  scope :true_virtual, -> {where(is_virtual: false)}

  before_save :set_serial_number_and_depth, if: -> (dep) { dep.new_record? && dep.parent_id != 0 }
  before_save :set_full_name
  after_save :update_parent_childrens_index, unless: -> (dep) { dep.parent.blank? }

  has_many :positions
  has_many :childrens, class_name: "Department", foreign_key: 'parent_id', inverse_of: :parent
  has_many :employees
  has_many :department_salaries

  belongs_to :parent, class_name: "Department", foreign_key: 'parent_id', inverse_of: :childrens, counter_cache: :childrens_count
  belongs_to :grade, class_name: "CodeTable::DepartmentGrade", foreign_key: 'grade_id'
  belongs_to :nature, class_name: "CodeTable::DepartmentNature", foreign_key: 'nature_id'

  validates :serial_number, uniqueness: true
  validate :presence_columns

  def presence_columns
    errors.add(:name, I18n.t("errors.messages.#{self.class.to_s}.name")) if self.name.blank?
    errors.add(:parent_id, I18n.t("errors.messages.#{self.class.to_s}.parent_id")) if self.parent_id.blank?
  end

  def version
    DepartmentChangeLog.latest_version.first.id
  end

  def model
    "department"
  end

  def parent_chain
    serial_number = self.serial_number
    query_str, query_parms = "", []

    while serial_number.length > 6
      query_str << "serial_number like ? or "
      serial_number = serial_number.slice(0...-3)
      query_parms << "%#{serial_number}"
    end

    if query_str.empty?
      [self]
    else
      Department.where(query_str.sub(/or\s$/, ''), *query_parms).to_a << self
    end
  end

  def parent_chain_exclude_self
    self.parent_chain - [self]
  end

  def get_full_name
    self.full_name = self.parent_chain.map(&:name).join('-')
  end

  def can_destroy?
    (self.childrens_count == 0 || self.childrens_count - Action.model("department").category_with('destroy').search_by(parent_id: self.id).count == 0) && self.positions.count == 0
  end

  def build_params
    self.set_serial_number_and_depth
    {
      serial_number: self.serial_number,
      id: (::PrimaryKey.get_autoincrement_id("department")),
      depth: self.depth,
      d1_sort_no: self.d1_sort_no,
      d2_sort_no: self.d2_sort_no,
      d3_sort_no: self.d3_sort_no
    }
  end

  def snapshot_attributes
    self.attributes.merge("grade" => self.grade.attributes, "nature" => self.nature.try(:attributes))
  end


  def root?
    self.parent_id == 0
  end


  def set_serial_number_and_depth(action=false, parent=Department.find_with_id(self.parent_id), transfer=false)
    if self.serial_number.blank? || action
      current_index, parent_number  = parent.childrens_index + 1, parent.serial_number
      current_index += Action.model('department').where("(category = 'transfer!' or category = 'create!')
        and data like '%\nparent_id: #{parent.id}\n%'").count
      self.serial_number = "#{parent_number}#{'0'*(3-current_index.to_s.size)}#{current_index}"
    end

    if self.depth.blank? || action
      self.depth = parent.depth + 1
    end
  end

  def get_underling
    Department.where("serial_number like ? and id != ?", "#{self.serial_number}%", self.id)
  end

  def get_underling_include_self
    Department.where("serial_number like ?", "#{self.serial_number}%")
      .preload(:positions)
  end

  def update_parent_childrens_index
    self.parent.update childrens_index: self.parent.childrens_index + 1 if self.new_record? || self.serial_number_changed?
  end

  def change_transfer parent
    self.parent_id = parent.id
    self.set_serial_number_and_depth(true, parent, true)
  end

  def set_sort_no(parent = self.parent)
    case parent.depth + 1
    when 2
      self.d1_sort_no = parent.childrens.present? ? parent.childrens.map(&:d1_sort_no).max + 1 : 1
      self.get_underling.update_all(d1_sort_no: self.d1_sort_no)
    when 3
      self.d1_sort_no = parent.d1_sort_no
      self.d2_sort_no = parent.childrens.present? ? parent.childrens.map(&:d2_sort_no).max + 1 : 1
      self.get_underling.update_all(
        d1_sort_no: self.d1_sort_no,
        d2_sort_no: self.d2_sort_no
      )
    else
      self.d1_sort_no = parent.d1_sort_no
      self.d2_sort_no = parent.d2_sort_no
      self.d3_sort_no = parent.childrens.present? ? parent.childrens.map(&:d3_sort_no).max + 1 : 1
    end
    return self
  end

  def set_full_name
    self.get_full_name if self.full_name.blank? or self.serial_number_changed?
    if self.name_changed?
      self.get_full_name
      set_childrens_full_name(self, self.full_name) if self.childrens
    end
  end

  def set_childrens_full_name(dep, parent_full_name)
    dep.childrens.each do |child|
      child.full_name = parent_full_name + '-' + child.name
      set_childrens_full_name(child, child.full_name) if child.childrens
      child.save
    end
  end

  def get_location
    case self.depth
    when 2
      ["d1_sort_no", self.d1_sort_no]
    when 3
      ["d2_sort_no", self.d2_sort_no]
    when 4
      ["d3_sort_no", self.d3_sort_no]
    end
  end

  def committee?
    ["党委办公室", "纪检（监察）办公室", "女职工委员会", "团委（青年工作部）", "工会办公室"].include?(name)
  end

  def update_location(target_place)
    case self.depth
    when 2
      self.update(d1_sort_no: target_place)
      self.get_underling.update_all(
        d1_sort_no: target_place
      )
    when 3
      self.update(d2_sort_no: target_place)
      self.get_underling.update_all(
        d2_sort_no: target_place
      )
    when 4
      self.update(d3_sort_no: target_place)
    end
  end

  def sort_no
    case self.depth
    when 1
      0
    when 2
      self.d1_sort_no
    when 3
      self.d2_sort_no
    when 4
      self.d3_sort_no
    end
  end

  class << self
    def get_set_book_no(dep, set_book_no = nil)
      return set_book_no if set_book_no.present?
      return 'root' if dep == self.root
      get_set_book_no(dep.parent, dep.set_book_no)
    end

    def find_with_id(id)
      department = self.where(id: id).first
      department ? department : Action.find_by_model_and_id(self, id)
    end

    def root
      Department.find_by(parent_id: 0)
    end

    def active_change!(change_log, current_employee=nil)
      # 1. 以后需要传入current_user的actions
      prediction = false # 默认变更未通过

      begin
        next_version = DepartmentChangeLog.next_version
        records = []
        Department.transaction do
          actions = ::Action.where(model: 'department')
          summary_date = Date.today.strftime("%Y-%m")

          record_value = []

          actions.each do |action|
            if action.category != "transfer!"
              change_log.step_desc += "#{action.localize_category} #{action.data["name"]};"

              # 考勤部分
              if action.category == 'create!' && action.data['depth'] == 2
                AttendanceSummaryStatusManager.create(department_id: action.data['id'], department_name: action.data['name'], summary_date: summary_date)
              end

              ## org_delete
              if action.category == 'destroy!'
                department = Department.find(action.data["id"])
                record_value << ['org_delete', {
                  oldName: department.name,
                  oldOrgNo: department.serial_number,
                  oldOrgD1SortNo: department.d1_sort_no,
                  oldOrgD2SortNo: department.d2_sort_no,
                  oldOrgD3SortNo: department.d3_sort_no,
                  oldGrade: {
                    level: department.grade.try(:level),
                    displayName: department.grade.try(:display_name)
                  },
                  newName: department.name,
                  newOrgNo: department.serial_number,
                  newOrgD1SortNo: department.d1_sort_no,
                  newOrgD2SortNo: department.d2_sort_no,
                  newOrgD3SortNo: department.d3_sort_no,
                  newGrade: {
                    level: department.grade.try(:level),
                    displayName: department.grade.try(:display_name)
                  }
                }]
              end
              if action.category == 'update!'
                department = Department.find(action.data['id'])
                record_value << ['org_modify', {
                  oldName: department.name,
                  oldOrgNo: department.serial_number,
                  oldOrgD1SortNo: department.d1_sort_no,
                  oldOrgD2SortNo: department.d2_sort_no,
                  oldOrgD3SortNo: department.d3_sort_no,
                  oldGrade: {
                    level: department.grade.try(:level),
                    displayName: department.grade.try(:display_name)
                  }
                }]
              end
            else
              department = Department.find(action.data["id"])
              parent_department = Department.find(action.data["parent_id"])

              # 修改考勤汇总数据
              if department.parent_id != parent_department.id && department.parent_chain.first != parent_department.parent_chain.first
                attendance_summaries = AttendanceSummary.where(department_id: department.id, summary_date: summary_date)
                status_manager = AttendanceSummaryStatusManager.find_by(department_id: department.parent_chain.first, summary_date: summary_date)
                new_status_manager = AttendanceSummaryStatusManager.find_by(department_id: parent_department.parent_chain.first, summary_date: summary_date)

                attendance_summaries.each do |attendance_summary|
                  attendance_summary.update!(attendance_summary_status_manager_id: new_status_manager.id)
                end

                if department.depth == 2 # 这里应该要删除吧？
                  status_manager && status_manager.destroy!
                end
              end

              before = Department.find(action.data["id"]).parent.name
              after = Department.find(action.data["parent_id"]).name
              change_log.step_desc += "【#{action.data["name"]}】从#{before}#{action.localize_category}到#{after};" if before != after
              # org_modify
              department = Department.find(action.data['id'])

              record_value << ['org_modify', {
                oldName: department.name,
                oldOrgNo: department.serial_number,
                oldOrgD1SortNo: department.d1_sort_no,
                oldOrgD2SortNo: department.d2_sort_no,
                oldOrgD3SortNo: department.d3_sort_no,
                oldGrade: {
                  level: department.grade.try(:level),
                  displayName: department.grade.try(:display_name)
                }
              }]
            end
          end

          ::Action.batch_execute(Department, Action.all, true)

          actions.each_with_index do |action, index|
            if ['update!', 'transfer!'].include?(action.category)
              department = Department.find(action.data['id'])
              records << ChangeRecord.save_record('org_modify', record_value[index][1].merge!({
                newName: department.name,
                newOrgNo: department.serial_number,
                newOrgD1SortNo: department.d1_sort_no,
                newOrgD2SortNo: department.d2_sort_no,
                newOrgD3SortNo: department.d3_sort_no,
                newGrade: {
                  level: department.grade.try(:level),
                  displayName: department.grade.try(:display_name)
                }
              }))
            elsif action.category == 'create!'
              department = Department.find_by(serial_number: action.data['serial_number'])
              records << ChangeRecord.save_record('org_add', {
                oldName: department.name,
                oldOrgNo: department.serial_number,
                oldOrgD1SortNo: department.d1_sort_no,
                oldOrgD2SortNo: department.d2_sort_no,
                oldOrgD3SortNo: department.d3_sort_no,
                oldGrade: {
                  level: department.grade.try(:level),
                  displayName: department.grade.try(:display_name)
                },
                newName: department.name,
                newOrgNo: department.serial_number,
                newOrgD1SortNo: department.d1_sort_no,
                newOrgD2SortNo: department.d2_sort_no,
                newOrgD3SortNo: department.d3_sort_no,
                newGrade: {
                  level: department.grade.try(:level),
                  displayName: department.grade.try(:display_name)
                }
              })
            else
              records << ChangeRecord.save_record(record_value[index][0], record_value[index][1])
            end
          end

          actions.destroy_all
          change_log.save!

          Department.take_snapshot(next_version)
          # Position.take_snapshot(next_version)
          # Employee.take_snapshot(next_version)
        end
        # 运行成功，生成机构的整体excel
        ExcelDeliverWorker.perform_async(Department.root.id, next_version)
        records.each do |record|
          record.send_notification
        end

        prediction = true
      rescue Exception => ex
        logger.error ex
        raise "Error happend in active process" #应该记录失败日志
      ensure
        return prediction
      end
    end

    def revert_change!
      ::Action.destroy_all
    end

    def get_self_and_childrens ids
      Department.where(id: ids).inject([]) do |deps, dep|
        deps << Department.where("serial_number like ?", "#{dep.serial_number}%").to_a
      end.flatten.map(&:id)
    end
  end

  private
  class << self
    def sort(current_id, target_id)
      current_item  = self.find current_id
      current_place = current_item.get_location
      target_item   = self.find target_id
      target_place  = target_item.get_location

      if current_place[1] > target_place[1]
        #排序上升
        self.where(
          "depth = ?  and parent_id = ? and #{current_place[0]} >= ? and #{current_place[0]} < ?",\
          current_item.depth,\
          current_item.parent_id,
          target_place[1],\
          current_place[1]
        ).each do |department|
          department.update(current_place[0] => department.send(current_place[0]) + 1)
          department.get_underling.update_all("#{current_place[0]} = #{current_place[0]} + 1")
        end
      else
        #排序下降
        self.where(
          "depth = ? and parent_id = ? and #{current_place[0]} > ? and #{current_place[0]} <= ?",\
          current_item.depth,\
          current_item.parent_id,\
          current_place[1],\
          target_place[1]
        ).each do |department|
          department.update(current_place[0] => department.send(current_place[0]) - 1)
          department.get_underling.update_all("#{current_place[0]} = #{current_place[0]} - 1")
        end
      end
      #更新自己
      current_item.update_location(target_place[1])
    end
  end
end
