class Attendance < ActiveRecord::Base
  scope :flight_grounded, -> { where("record_type like ?", "%空勤停飞")}
  scope :flight_ground_work, -> { where("record_type like ?", "%空勤地面工作")}
  scope :late_or_early_leave, -> { where("(record_type like ?) or (record_type like ?)", "%迟到", "%早退")}
  scope :absence, -> { where("record_type like ?", "%旷工") }

  validates :employee_id, :record_type, :record_date, presence: true

  belongs_to :employee

  # validate :check_record_date, :if => Proc.new{|model| model.record_date.present? }

  after_save do 
    record_types = self.record_type.split("-")
    AttendanceCalculator.change_attendance_days(record_types.first, record_types.last, self.employee, self.record_date) if for_update?
    AttendanceCalculator.reduce_attendance_days(self.record_type, self.employee, self.record_date) if for_delete?
    AttendanceCalculator.add_attendance_days(self.record_type, self.employee, self.record_date) if !(for_delete? || for_update?)
  end

  after_create :send_messages, if: -> (att) { att.record_type == '旷工' }

  def update_type(record_type)
    type_array = self.record_type.split("-")
    type_array << record_type

    while type_array.size > 2
      type_array.shift
    end

    self.record_type = type_array.join("-")
    self.is_delete = true if record_type == "删除"
    self.save
  end

  def send_messages
    begin_date = self.record_date.at_beginning_of_year
    count = Attendance.where("record_type = '旷工' and employee_id = #{self.employee_id} and record_date >= #{begin_date}").count
    if count > 5
      recever_ids = Flow.hr_labor_relation_member
      recever_ids.each do |recever_id|
        unless Employee.find_by(id: recever_id).blank?
          Notification.send_user_message(recever_id, "important", "#{self.employee.department.full_name}员工：#{self.employee.name}已旷工#{count}次！")
        end
      end
    end
  end

  private
  def for_update?
    self.record_type =~ /-/ && self.is_delete == false
  end

  def for_delete?
    self.record_type =~ /-/ && self.is_delete == true
  end

  def check_record_date
    errors.add(:record_date, '考勤的日期不能大于今天') if self.record_date.to_date > Date.today
  end
end
