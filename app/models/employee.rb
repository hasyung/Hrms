class Employee < ActiveRecord::Base
  serialize :old_education_data, Hash
  serialize :special_ca, Array

  audited except: [
    :sort_no, :pinyin_name, :pinyin_index, :crypted_password,
    :favicon, :favicon_type, :favicon_size, :bit_value,
    :last_login_ip, :last_login_at, :department_id, :pcategory,
    :annuity_cardinality, :annuity_status, :annuity_account_no,
    :identity_name, :flow_contact_people, :hours_fee_category,
    :probation_months, :leave_flyer_student_date,
    :classification, :salary_set_book, :personal_reserved_funds,
    :is_system, :old_education_data, :is_virtual, :virtual_name,
    :is_admin, :month_distribute_base, :old_employee_no,
    :change_contract_date, :change_contract_system_date,
    :change_education_date, :is_stop_salary, 
    :salary_set_book, :special_ca, :bus_fee, :leave_days
  ]

  include Pinyinable
  include Snapshotable
  include Connectable
  include Uploaderable

  attr_accessor :password
  DEFAULT_PASSWORD = '123456'

  serialize :flow_contact_people, Array

  default_scope {where(is_delete: false).where(is_virtual: false).where(is_system: false)} #is_delete: 标志员工是否被辞退，离职 is_virtual: 是否是虚拟公司（商旅公司）的员工
  scope :recent_entrants, ->{ where("employees.join_scal_date >= ?", Date.today.advance(years: -1)).order('asc') }

  before_create do
    self.start_work_date ||= self.join_scal_date
    self.employment_status_id ||= Employee::EmploymentStatus.find_by(display_name: '正式员工').try(:id)
  end

  # after_update :clear_salary_person_setup, if: -> (employee) { employee.channel_id_changed? }

  belongs_to :category, class_name: "CodeTable::Category"
  belongs_to :channel, class_name: "CodeTable::Channel"

  #码表
  belongs_to :gender, class_name: "CodeTable::Gender", foreign_key: 'gender_id'
  belongs_to :political_status, class_name: "CodeTable::PoliticalStatus", foreign_key: 'political_status_id'
  belongs_to :english_level, class_name: "CodeTable::EnglishLevel", foreign_key: 'english_level_id'
  belongs_to :marital_status, class_name: "CodeTable::MaritalStatus", foreign_key: 'marital_status_id'
  belongs_to :education_background, class_name: "CodeTable::EducationBackground", foreign_key: 'education_background_id'
  belongs_to :degree, class_name: "CodeTable::Degree", foreign_key: 'degree_id'
  belongs_to :duty_rank, class_name: "Employee::DutyRank"
  belongs_to :job_title_degree, class_name: "Employee::JobTitleDegree"
  belongs_to :employment_status, class_name: "Employee::EmploymentStatus"
  belongs_to :labor_relation, class_name: "Employee::LaborRelation"
  belongs_to :department

  has_one :social_person_setup
  has_one :salary_person_setup
  has_one :salary_grade_change
  has_one :flyer_info
  has_one :contact, class_name: "Employee::ContactWay", :dependent => :destroy
  has_one :personal_info, class_name: "Employee::PersonalInfo", :dependent => :destroy
  has_one :set_book_info, class_name: "SetBook::Info", dependent: :destroy
  has_one :offset_days_record,
    -> { where(vacation_records: {record_type: '补休假'}).limit(1)},
    class_name: 'VacationRecord'

  has_many :languages, dependent: :destroy
  has_many :upgrade_grade_infos, dependent: :destroy
  has_many :employee_positions, -> { order(:sort_index) }
  has_many :positions, :through => :employee_positions
  has_many :master_positions,
    -> { where('employee_positions.category = "主职" and employee_positions.sort_index = 0') },
    :through => :employee_positions,
    source: :position
  has_many :employee_permissions, :dependent => :destroy
  has_many :authenticate_tokens, :dependent => :destroy
  has_many :search_conditions, class_name: "Employee::SearchCondition",:dependent => :destroy
  has_many :education_experiences, class_name: "Employee::EducationExperience", :dependent => :destroy
  has_many :work_experiences, class_name: "Employee::WorkExperience", :dependent => :destroy
  has_many :family_members, class_name: "Employee::FamilyMember", :dependent => :destroy
  has_many :flows, class_name: "Flow", foreign_key: "sponsor_id", :dependent => :destroy
  has_many :own_flows, class_name: "Flow", foreign_key: "receptor_id", :dependent => :destroy
  has_many :notifications, :dependent => :destroy
  has_many :attendances, :dependent => :destroy
  has_many :vacation_records, :dependent => :destroy
  has_many :performances
  has_many :attendance_summaries
  has_many :contracts, class_name: "Contract"
  has_many :agreements
  has_many :social_cardinalities
  has_many :social_records
  has_many :social_change_infos
  has_many :annuities
  has_many :annuity_applies
  has_many :annuity_notes
  has_many :special_states,  -> { order(special_date_to: 'desc', special_date_from: 'asc') }
  has_many :basic_salaries
  has_many :performance_salaries
  has_many :allowances
  has_many :land_allowances
  has_many :rewards
  has_many :hours_fees
  has_many :punishments
  has_many :department_change_logs
  has_many :salary_changes
  has_many :calc_steps
  has_many :keep_salaries
  has_many :position_change_records
  has_many :technical_grade_change_records
  has_many :dinner_person_setups
  has_many :dinner_changes
  has_many :birth_allowances
  has_many :transport_fees
  has_many :birth_salaries
  has_many :position_records
  has_many :education_experience_records
  has_many :airline_fees
  has_many :set_book_change_records, class_name: "SetBook::ChangeRecord", dependent: :destroy
  has_many :fav_notes, dependent: :destroy
  has_many :bus_fees
  has_many :official_cars
  has_many :reports
  has_many :security_fees
  has_many :cabin_vacation_imports, class_name: "CabinVacationImport", foreign_key: "employee_id"
  has_one  :salary_setup_cache
  has_many :technical_records
  has_one  :early_retire_employee
  has_many :work_shifts
  has_many :title_info_change_records

  accepts_nested_attributes_for :personal_info
  accepts_nested_attributes_for :education_experiences
  accepts_nested_attributes_for :family_members
  accepts_nested_attributes_for :languages

  before_save :encrypt_password, :if => :password_required
  after_save :create_contact_and_personal_info

  # Uploader
  uploader_image :favicon, FaviconUploader, size: 5

  def me_presence_columns
    errors.add(:name, I18n.t("errors.messages.#{self.class.to_s}.name")) if self.name.blank?
    errors.add(:nationality, I18n.t("errors.messages.#{self.class.to_s}.nationality")) if self.nationality.blank?
    errors.add(:nation, I18n.t("errors.messages.#{self.class.to_s}.nation")) if self.nationality == '中国' && self.nation.blank?
    errors.add(:native_place, I18n.t("errors.messages.#{self.class.to_s}.native_place")) if self.native_place.blank?
    errors.add(:birth_place, I18n.t("errors.messages.#{self.class.to_s}.birth_place")) if self.birth_place.blank?
    errors.add(:identity_no, I18n.t("errors.messages.#{self.class.to_s}.identity_no")) if self.identity_no.blank?
    errors.add(:marital_status_id, I18n.t("errors.messages.#{self.class.to_s}.marital_status_id")) if self.marital_status_id.blank?
  end

  def employee_presence_columns
    errors.add(:name, I18n.t("errors.messages.#{self.class.to_s}.name")) if self.name.blank?
    errors.add(:join_scal_date, I18n.t("errors.messages.#{self.class.to_s}.join_scal_date")) if self.join_scal_date.blank? && self.start_internship_date.blank?
    errors.add(:identity_no, I18n.t("errors.messages.#{self.class.to_s}.identity_no")) if self.identity_no.blank?
    errors.add(:birthday, I18n.t("errors.messages.#{self.class.to_s}.birthday")) if self.birthday.blank?
    errors.add(:education_background_id, I18n.t("errors.messages.#{self.class.to_s}.education_background_id")) if self.education_background_id.blank?
    errors.add(:political_status_id, I18n.t("errors.messages.#{self.class.to_s}.political_status_id")) if self.political_status_id.blank?
    errors.add(:labor_relation_id, I18n.t("errors.messages.#{self.class.to_s}.labor_relation_id")) if self.labor_relation_id.blank?
    errors.add(:category_id, I18n.t("errors.messages.#{self.class.to_s}.category_id")) if self.category_id.blank?
    errors.add(:channel_id, I18n.t("errors.messages.#{self.class.to_s}.channel_id")) if self.channel_id.blank?
    errors.add(:location, I18n.t("errors.messages.#{self.class.to_s}.location")) if self.location.blank?
    errors.add(:employee_no, I18n.t("errors.messages.#{self.class.to_s}.employee_no")) if self.employee_no.blank?
    errors.add(:employee_no, I18n.t("errors.messages.#{self.class.to_s}.employee_no_taken")) if Employee.where(employee_no: self.employee_no).present? && self.new_record?
  end

  def employee_basic_columns
    errors.add(:name, I18n.t("errors.messages.#{self.class.to_s}.name")) if self.name.blank?
    errors.add(:join_scal_date, I18n.t("errors.messages.#{self.class.to_s}.join_scal_date")) if self.join_scal_date.blank? && self.start_internship_date.blank?
    errors.add(:identity_no, I18n.t("errors.messages.#{self.class.to_s}.identity_no")) if self.identity_no.blank?
    errors.add(:birthday, I18n.t("errors.messages.#{self.class.to_s}.birthday")) if self.birthday.blank?
    errors.add(:education_background_id, I18n.t("errors.messages.#{self.class.to_s}.education_background_id")) if self.education_background_id.blank?
    errors.add(:political_status_id, I18n.t("errors.messages.#{self.class.to_s}.political_status_id")) if self.political_status_id.blank?
    errors.add(:employee_no, I18n.t("errors.messages.#{self.class.to_s}.employee_no")) if self.employee_no.blank?
    errors.add(:employee_no, I18n.t("errors.messages.#{self.class.to_s}.employee_no_taken")) if Employee.where(employee_no: self.employee_no).present? && self.new_record?
  end

  def employee_position_columns
    errors.add(:labor_relation_id, I18n.t("errors.messages.#{self.class.to_s}.labor_relation_id")) if self.labor_relation_id.blank?
    errors.add(:category_id, I18n.t("errors.messages.#{self.class.to_s}.category_id")) if self.category_id.blank?
    errors.add(:channel_id, I18n.t("errors.messages.#{self.class.to_s}.channel_id")) if self.channel_id.blank?
    errors.add(:location, I18n.t("errors.messages.#{self.class.to_s}.location")) if self.location.blank?
  end

  def has_permission?(bits, permission)
    bit_value = permission.bit_value.to_i
    bits & bit_value == bit_value
  end

  def is_contract_regulation?
    ["合同制"].include?(self.labor_relation.try(:display_name))
  end

  def is_contract_type_regulation?
    ["合同", "合同制"].include?(self.labor_relation.try(:display_name))
  end

  def has_bits?(bits, bit_value)
    bit_value = bit_value.to_i
    bits & bit_value == bit_value
  end

  def has_controller_action?(controller, action)
    permission = Permission.find_by(controller: controller, action: action)
    return false unless permission
    self.has_permission?(self.employee_bits, permission)
  end

  def get_all_controller_actions
    bits = self.employee_bits

    Permission.all.inject([]) do |result, permission|
      result << permission if self.has_permission?(bits, permission)
      result
    end
  end

  def get_roles_controller_actions
    bits = self.roles_permission_bits

    Permission.all.inject([]) do |result, permission|
      result << permission if self.has_permission?(bits, permission)
      result
    end
  end

  def employee_bits
    self.cleanup_permission

    temp = self.employee_permissions.map(&:bit_value).map(&:to_i).inject{|result, x| result|x}
    temp.to_i | self.bit_value.to_i | self.roles_permission_bits
  end

  def roles_permission_bits
    per_ids = PermissionGroup.where("name in (?)", self.get_my_roles | ["new_employee"]).flat_map(&:permission_ids)
    Permission.where("id in (?)", per_ids).map(&:bit_value).map(&:to_i).inject{|result, x| result|x}.to_i
  end

  def cleanup_permission
    self.employee_permissions.where("expire_time <= ?", Time.now).destroy_all
  end


  def self.authenticate(employee_no, password)
    # employee = Employee.unscoped.where(employee_no: employee_no, is_delete: false).first if employee_no.present?
    # 离职的人修改密码不让登陆，退养的人不修改密码，但是他们都不出现在花名册中，并且is_delete都是true
    employee = Employee.unscoped.where(employee_no: employee_no).first if employee_no.present?
    employee && employee.has_password?(password) ? employee : nil
  end

  def has_password?(password)
    ::BCrypt::Password.new(crypted_password) == password
    
  end

  def snapshot_attributes
    self.attributes.merge("education_background" => self.education_background.try(:attributes),
      "political_status" => self.political_status.try(:attributes), "contact" => self.contact.try(:attributes),
      "employee_positions" => self.employee_positions.map(&:attributes), "gender" => self.gender.try(:attributes)
    )
  end

  def fix_sort_no_and_department_id(department_id)
    # 如果没有更新主岗位，那么不操作sort_no
    return if self.department_id == department_id

    order_sort_no = Employee.where(department_id: department_id).map(&:sort_no ).max
    sort_no = order_sort_no ? (order_sort_no + 1) : 1
    self.update(department_id: department_id, sort_no: sort_no)
  end

  def depart?
    self.employment_status && self.employment_status.display_name == '离职员工'
  end

  def master_position
    self.master_positions.first
  end

  def leave_company(reason, date = nil)
    self.employee_positions.each{ |emp_pos| emp_pos.change_position }
    self.update(is_delete: true, approve_leave_job_date: (date || Time.new.to_date),
      leave_job_reason: reason, password: SecureRandom.hex(4))

    # 如果从退养列表里离职需要删除退养数据
    EarlyRetireEmployee.find_by(employee_id: self.id).try(:destroy)
  end

  def early_retire(date = nil)
    self.update(is_delete: true, early_retire_date: (date || Time.new.to_date))
  end

  def self.full_join(model)
    model.joins("LEFT JOIN `employees` ON `employees`.`id` = `attendances`.`employee_id` AND `employees`.`is_delete` = 0 AND `employees`.`is_virtual` = 0")
         .joins("LEFT JOIN `employee_job_title_degrees` ON `employee_job_title_degrees`.`id` = `employees`.`job_title_degree_id`")
         .joins("LEFT JOIN `code_tables` ON `code_tables`.`id` = `employees`.`gender_id` AND `code_tables`.`type` IN ('CodeTable::Gender')")
         .joins("LEFT JOIN `code_tables` `political_statuses_employees` ON `political_statuses_employees`.`id` = `employees`.`political_status_id` AND `political_statuses_employees`.`type` IN ('CodeTable::PoliticalStatus')")
         .joins("LEFT JOIN `code_tables` `education_backgrounds_employees` ON `education_backgrounds_employees`.`id` = `employees`.`education_background_id` AND `education_backgrounds_employees`.`type` IN ('CodeTable::EducationBackground')")
         .joins("LEFT JOIN `employee_contact_ways` ON `employee_contact_ways`.`employee_id` = `employees`.`id`")
         .joins("LEFT JOIN `employee_positions` ON `employee_positions`.`employee_id` = `employees`.`id` AND `employee_positions`.`end_date` IS NULL")
         .joins("LEFT JOIN `positions` ON `positions`.`id` = `employee_positions`.`position_id` AND (employee_positions.category = '主职')")
         .joins("LEFT JOIN `code_table_categories` ON `code_table_categories`.`id` = `employees`.`category_id`")
         .joins("LEFT JOIN `employee_labor_relations` ON `employee_labor_relations`.`id` = `employees`.`labor_relation_id`")
         .joins("LEFT JOIN `code_table_channels` ON `code_table_channels`.`id` = `employees`.`channel_id`")
         .joins("LEFT JOIN `employee_positions` `employee_positions_employees_join` ON `employee_positions_employees_join`.`employee_id` = `employees`.`id` AND `employee_positions_employees_join`.`end_date` IS NULL")
         .joins("LEFT JOIN `positions` `positions_employees` ON `positions_employees`.`id` = `employee_positions_employees_join`.`position_id`")
         .joins("LEFT JOIN `departments` ON `departments`.`id` = `positions_employees`.`department_id`")
  end

  def language_names
    self.languages.inject([]) do |names, language|
      names << "#{language.name}: #{language.grade}" if language.name && language.grade
      names
    end.join('/')
  end

  # 是否是空勤
  def is_air_duty?
    ["飞行", "空勤"].include?(self.try(:channel).try(:display_name))
  end

  # 总年假天数
  def total_year_days
    VacationRecord.total_days(self.id)
  end

  # 违规扣年假
  # 1. 请事假超过25天
  # 2. 请病假违规
  # violation_name = ["病假", "事假", "派驻人员休假"]
  def force_reduce_year_days(violation_name)
    VacationRecord.force_reduce_days(self.id)
    VacationViolation.find_or_create_by(employee_id: self.id, category: violation_name)
  end

  # 恢复违规扣除的年假
  def restore_reduce_year_days(violation_name)
    VacationRecord.restore_reduce_days(self.id)
    @record = VacationViolation.where(employee_id: self.id, category: violation_name).first
    @record.try(:destroy)
  end

  # 违规类型
  def violation_list
    self.vacation_violations.map(&:category).uniq
  end

  # 员工补休假天数
  def offset_days
    self.offset_days_record.present? ? self.offset_days_record.days : 0
  end

  # 设置补休假天数
  def set_offset_days(days)
    if self.offset_days_record.present?
      self.offset_days_record.update(days: days)
    else
      self.build_offset_days_record(days: days).save
    end
  end

  # 扣除补休假
  def reduce_offset_days(days)
    VacationRecord.reduce_offset_days(self.id, days)
  end

  # 扣年假或者请年假
  def reduce_year_days(days, year = nil)
    year = Time.new.to_date.year unless year
    VacationRecord.reduce_days(self.id, year, days)
  end

  # 添加年假
  def add_year_days(days, year = nil)
    year = Time.new.to_date.year unless year
    VacationRecord.add_days(self.id, year, days)
  end

  #假期概要
  def vacation_summary
    hash = {}
    hash[:enable_vacation]     = VacationRecord.enable_vacation(self.id) # 可以请假的类型
    hash[:year_days]           = VacationRecord.year_days(self.id) # 年假
    hash[:init_year_days]      = VacationRecord.find_by(employee_id:id, record_type:'年假', year:Time.now.year).try(:init_days) # 当年年假总天数
    hash[:offset_days]         = self.offset_days # 补休假
    hash[:start_working_years] = self.start_working_years # 工作年限
    hash[:scal_working_years]  = self.scal_working_years
    hash[:is_air_duty]         = self.is_air_duty?  # 是否属于空勤
    hash
  end

  def scal_working_years
    return nil unless self.join_scal_date
    Date.difference_in_years(Time.new.strftime("%Y-%m-%d"), self.join_scal_date.strftime("%Y-%m-%d"))
  end

  def start_working_years
    return nil unless self.start_work_date
    Date.difference_in_years(Time.new.strftime("%Y-%m-%d"), self.start_work_date.strftime("%Y-%m-%d"))
  end

  def age
    return nil unless self.birthday
    Date.difference_in_years(Time.new.strftime("%Y-%m-%d"), self.birthday.strftime("%Y-%m-%d"))
  end

  def master_position_years
    employee_position = self.employee_positions.find_by(category: '主职')
    return nil unless employee_position
    Date.difference_in_years(Time.new.strftime("%Y-%m-%d"), employee_position.start_date.strftime("%Y-%m-%d"))
  end

  def last_contact_duration
    contact = self.contracts.order("created_at desc").first
    return nil unless contact
    contact.contract_duration_date
  end

  def year_performance
    self.performances.where(category: 'year').order("created_at desc").first.try(:result)
  end

  def get_any_performances(count)
    performances = self.performances.where(category: 'month').order("created_at desc").first(count)
    return nil unless performances
    performances.group_by{|per|per.result}.inject([]){|arr, pers| arr << "#{pers[1].size}次#{pers[0]}"}.join("/")
  end

  def leave_date
    LeaveEmployee.find_by(name: self.name, employee_no: self.employee_no).try(:created_at).try(:to_date)
  end

  def working_years_salary
    return 0 unless self.scal_working_years
    self.scal_working_years * 40
  end

  def last_year_perf
    # 员工去年年度绩效考核结果
    # 获得去年的绩效结果，有 "优秀/良好/合格/待改进"，新进员工返回 "随动"
    return "随动" if self.join_scal_date > Date.today - 2.year
    self.performances.where(category: 'year', assess_year: Date.today.last_year.year).first.try(:result)
  end

  def is_female?
    self.try(:gender).try(:display_name).to_s == "女"
  end

  def is_male?
    self.try(:gender).try(:display_name).to_s == "男"
  end

  def department_hr?
    self.positions.map(&:id).each do |pos_id|
      return true if FlowRelation.where('role_name = "department_hr" and position_ids like "%- ?\n%"', pos_id.to_s).present?
    end
    false
  end

  def hr_leader?
    department_id = Department.find_by(name: '人力资源部').try(:id)
    return false if department_id.blank?

    self.positions.pluck(:id).each do |pos_id|
      return true if FlowRelation.where('role_name = "hr_leader" and position_ids like "%- ?\n%" and department_id = ?', pos_id.to_s, department_id).present?
    end

    return false
  end

  def self.hr_leaders
    pos_ids = FlowRelation.where(role_name: 'hr_leader').map(&:position_ids).flatten.map(&:to_i)
    Employee.joins(:positions).where("positions.id in (?)", pos_ids)
  end

  def hr_labor_relation_leader?
    department_id = Department.find_by(name: '劳动关系管理室').try(:id)
    return false if department_id.blank?

    self.positions.pluck(:id).each do |pos_id|
      return true if FlowRelation.where('role_name = "department_leader" and position_ids like "%- ?\n%" and department_id = ?', pos_id.to_s, department_id).present?
    end

    return false
  end

  def hr?
    serial_number = Department.find_by(name: '人力资源部').try(:serial_number)
    return false if serial_number.blank?
    dep_ids = Department.where("serial_number like ?", serial_number + '%').map(&:id)
    self.positions.map(&:department_id).each do |department_id|
      return true if dep_ids.include?(department_id)
    end
    false
  end

  def hr_labor_relation_member?
    serial_number = Department.find_by(name: '劳动关系管理室').try(:serial_number)
    return false if serial_number.blank?
    dep_ids = Department.where("serial_number like ?", serial_number + '%').map(&:id)
    position_ids = FlowRelation.where('role_name = "hr_labor_relation_member" and department_id in (?)',
         dep_ids).flat_map(&:position_ids).map(&:to_i)
    self.positions.map(&:id).each do |pos_id|
      return true if position_ids.include?(pos_id)
    end
    false
  end

  def hr_payment_member?
    position_ids = FlowRelation.where('role_name = "hr_payment_member"').flat_map(&:position_ids).map(&:to_i)
    self.positions.map(&:id).each do |pos_id|
      return true if position_ids.include?(pos_id)
    end
    false
  end

  #role_name = 'department_hr' or 'department_leader'
  def get_departments_for_role
    department_ids = self.positions.map(&:id).inject([]) do |arr, pos_id|
      arr << FlowRelation.where('(role_name = "department_hr" or role_name = "department_leader" or role_name = "county_leader" 
        or role_name = "family_leader") and position_ids like "%- ?\n%"', pos_id.to_s).map(&:department_id)
    end.flatten.uniq
    department_ids = Department.get_self_and_childrens(department_ids) if department_ids.present?
    department_ids
  end

  def company_leader?
    position_ids = FlowRelation.where('role_name = "company_leader"').map(&:position_ids).flatten.uniq
    return false if position_ids.blank?
    self.positions.map(&:id).each do |pos_id|
      return true if position_ids.include?(pos_id.to_s)
    end
    false
  end

  def join_annuity
    unless self.annuity_status
      cal_annuity_cardinality
      self.update(annuity_status: true)
    end
  end

  def exit_annuity
    if self.annuity_status
      self.update(annuity_status: false)
    end
  end

  def cal_annuity_cardinality
    if self.annuity_account_no.blank?
      annuity_cardinality = SocialRecord.cal_annuity_cardinality(self)
      self.update(annuity_cardinality: annuity_cardinality)
    end
  end

  def get_my_roles
    @roles = []

    self.positions.each do |position|
      @roles << FlowRelation.where("position_ids like '%- \\'#{position.id}\\'\n%'").map(&:role_name)
    end

    @roles = @roles.flatten.uniq

    roles = RoleMenu.order("level").map(&:role_name)
    @roles.delete_if{|x|!roles.include?(x)}
    @roles.sort{|x, y| roles.index(x) <=> roles.index(y)}
  end

  # 是否是干部
  def is_category_leader? categories = CodeTable::Category.all
    categories.select{|c| c.display_name == '干部'}.first.id == self.category_id
  end

  # 是否是领导
  def is_category_super_leader? categories = CodeTable::Category.all
    categories.select{|c| c.display_name == '干部'}.first.id == self.category_id
  end

  # 是否是领导和干部
  def is_leader? categories = CodeTable::Category.all
    is_category_leader?(categories) || is_category_super_leader?(categories)
  end

  # 薪酬设置是否是飞行学员
  def is_flyer_student_channel?
    @steup ||= self.salary_person_setup
    @steup && @steup.fly_hour_fee == 'student'
  end

  # 是否是飞行通道
  def is_fly_channel?
    @channels ||= CodeTable::Channel.all
    @channels.find_by(id: self.channel_id).try(:display_name) == '飞行'
  end

  # 飞行员总飞行时间
  def fly_total_time
    self.flyer_info.present? ? self.flyer_info.total_fly_time : nil
  end

  # 飞行员驾驶经历年限
  def drive_date
    (self.flyer_info.present? && self.flyer_info.copilot_date.present?) ? self.flyer_info.copilot_date : nil
  end

  # 是否是空保大队和客舱服务部人员
  def is_kecang_or_kongbao
    return true if %w(空保大队 客舱服务部).include?(self.department.full_name.split('-').first)
  end

  # 飞行教员经历年限
  def teacher_date
    if self.flyer_info.present?
      date = []
      date << self.flyer_info.teacher_A_date if self.flyer_info.teacher_A_date.present?
      date << self.flyer_info.teacher_B_date if self.flyer_info.teacher_B_date.present?
      date << self.flyer_info.teacher_C_date if self.flyer_info.teacher_C_date.present?
      return date.min
    end
    return nil
  end

  # 员工上次调档时间
  def last_transfer_date
    self.upgrade_grade_infos.maximum(:last_up_date)
  end

  def record_transfer_date(date = Date.today.beginning_of_year)
    self.upgrade_grade_infos.create(last_up_date: date)
  end

  #更新员工岗位绩效变动待审核数据
  def update_salary_grade_change_record(category, setup, hash)
    item = SalaryGradeChange.find_or_create_by(employee_id: self.id, change_module: category, result: "checking")
    case category
    when "岗位工资"
      form_data = {
        original: {
          base_wage: setup.base_wage,
          base_channel: setup.base_channel,
          base_flag: setup.base_flag,
        },
        transfer_to: hash
      }
    else
      form_data = {
        original: {
          performance_wage: setup.performance_wage,
          performance_channel: setup.performance_channel,
          performance_flag: setup.performance_flag,

        },
        transfer_to: hash
      }
    end
    item.update(
      employee_no: self.employee_no,
      employee_name: self.name,
      department_name: self.department.full_name,
      position_name: self.master_position.name,
      last_transfer_date: self.last_transfer_date,
      labor_relation_id: self.labor_relation_id,
      fly_total_time: self.fly_total_time,
      channel_id: self.channel_id,
      record_date: Date.today,
      form_data: form_data,
    )
  end

  # 是否是空勤通道
  def is_air_service_channel?
    @channels ||= CodeTable::Channel.all
    @channels.find_by(id: self.channel_id).try(:display_name) == '空勤'
  end

  def evection_days(month)
    #员工出差天数
    self.attendance_summaries.where(summary_date: month).pluck(:evection).flatten.first.to_f
  end

  # 请假天数
  # 否则只计算当月请假的汇总数据总天数
  # month参数是个字符串, 比如2015-08
  def get_vacation_days(month)
    # 要包含旷工
    flows = self.own_flows.where("leave_date_record like ? AND workflow_state = 'actived'", "%#{month}%")
    deduct_records = flows.pluck(:deduct_leave_date).map{|record| record[month]}.compact
    records = flows.pluck(:leave_date_record).map{|record| record[month]}.compact
    leave_records = deduct_records + records
    absence_month = [month]

    absence_days = self.attendance_summaries.where(summary_date: absence_month).pluck(:absenteeism).map(&:to_i).inject(0, :+)
    days = leave_records.inject(0) do |result, record|
      if Flow::WORKING_DAYS_LEAVE_FLOW.include?(record["leave_type"])
        start_time, end_time = record["start_time"].to_datetime, record["end_time"].to_datetime
        result += VacationRecord.cals_days(
          employee_id: self.id,
          start_time: start_time,
          end_time: end_time,
          start_date: start_time.beginning_of_day.to_date,
          end_date: end_time.beginning_of_day.to_date,
          vacation_type: I18n.t("flow.type.#{record['leave_type']}"),
          is_contain_free_day: true
        )[:vacation_days]
      else
        result += record["vacation_days"]
      end

      result
    end

    summary = self.attendance_summaries.select{|s| s.summary_date == month}.first

    absence_days + days + summary.try(:cultivate).to_f + summary.try(:recuperate_leave).to_f + summary.try(:family_planning_leave).to_f
  end

  # 连续 standard_days 天以上的请假，并且跨 month 月和 month 上月
  def is_continue_vacation_days?(month, standard_days = 15)
    last_month = "#{month}-01".to_date.advance(months: -1).strftime("%Y-%m")
    flows = self.own_flows.where("(leave_date_record like ? OR leave_date_record like ?) AND workflow_state = 'actived'", "%#{month}%", "%#{last_month}%")
    leave_date_records = flows.pluck(:leave_date_record)
    deduct_leave_records = flows.pluck(:deduct_leave_date)
    records = (leave_date_records.map{|record| record[month]} + leave_date_records.map{|record| record[last_month]}).compact
    deduct_records = (deduct_leave_records.map{|record| record[month]} + deduct_leave_records.map{|record| record[last_month]}).compact
    leave_records = records + deduct_records

    start_date = "#{last_month}-01".to_date.end_of_month
    end_date = "#{month}-01".to_date

    hash_days = leave_records.inject({}) do |hash_days, record|
      Range.new(record["start_time"].to_date, record["end_time"].to_date).each do |date|
        next if date.end_of_month != start_date && date.beginning_of_month != end_date
        if (date == record["start_time"].to_date && record["start_time"].include?(Setting.daily_working_hours.afternoon)) || (date == record["end_time"].to_date && record["end_time"].include?(Setting.daily_working_hours.afternoon))
          if date == record["start_time"].to_date
            standard = 0.9
          else
            standard = 0.1
          end
          hash_days[date] = hash_days[date].to_f + standard
          hash_days[date] = standard if hash_days[date] == 0.2 || hash_days[date] == 1.8
        else
          hash_days[date] = 1
        end
      end
      hash_days
    end

    free_days = VacationRecord.check_free_days(start_date.advance(days: -(standard_days - 1)), end_date.advance(days: +(standard_days - 1)))
    free_days.each{|date| hash_days[date] = 1} if self.master_position.schedule.try(:display_name) == "标准工时制"

    return false if hash_days.values.inject(:+).to_f <= standard_days

    dates = Range.new(start_date.advance(days: -(standard_days - 1)), end_date.advance(days: +(standard_days - 1))).to_a
    days = 0
    dates.each do |date|
      if hash_days[date].blank?
        return true if days > standard_days
        days = 0
      else
        if hash_days[date] != 1
          days += 0.5 if hash_days[date] == 0.1
          if days > standard_days
            return true
          else
            days = hash_days[date] == 1 ? 1 : hash_days[date] == 0.9 ? 0.5 : 0
          end
        else
          days += 1
        end
      end
    end

    days > standard_days
  end

  # past_months 则是上2个月(month, month - 1)时间内，否则是 month 那个月
  # type = vacation 休假，所有假(自然日)
  # type = leave_position 离岗(自然日)
  # type = business_trip 出差(自然日)
  def get_attendance_type_days(type, month, past_months = 1)
    AttendanceSummary.send("get_attendance_type_days_by_#{type}", self, month, past_months)
  end

  # 非事假和旷工的哈希表集合
  def get_no_personal_leave_dates(month)
    flows = self.own_flows.where("(leave_date_record like ? OR deduct_leave_date like ?) AND workflow_state = 'actived' AND (leave_date_record not like '%Flow::PersonalLeave%' OR deduct_leave_date not like '%Flow::PersonalLeave%')", "%#{month}%", "%#{month}%")
    records = flows.pluck(:leave_date_record).map{|record| record[month]}.compact
    deduct_records = flows.pluck(:deduct_leave_date).map{|record| record[month]}.compact

    (records + deduct_records).inject({}) do |result, record|
      start_date, end_date = record["start_time"].to_date, record["end_time"].to_date
      vacation_days = 0

      if start_date == end_date
        if Flow::WORKING_DAYS_LEAVE_FLOW.include?(record["leave_type"])
          vacation_days = VacationRecord.cals_days(
            employee_id: self.id,
            start_time: record["start_time"].to_datetime,
            end_time: record["end_time"].to_datetime,
            start_date: start_date,
            end_date: end_date,
            vacation_type: I18n.t("flow.type.#{record['leave_type']}"),
            is_contain_free_day: true
          )[:vacation_days]
        else
          vacation_days = record["vacation_days"]
        end

        if result[start_date]
          result[start_date] += vacation_days
        else
          result[start_date] = vacation_days
        end
      else
        working_dates = Range.new(start_date, end_date).to_a
        working_dates.each do |date|
          if (date == start_date && record["start_time"].include?("#{Setting.daily_working_hours.afternoon}")) || (record["end_time"].include?("#{Setting.daily_working_hours.afternoon}") && date == end_date)
            vacation_days = 0.5
          else
            vacation_days = 1
          end

          if result[date]
            result[date] += vacation_days
          else
            result[date] = vacation_days
          end
        end
      end

      result
    end
  end

  # 事假日期哈希表集合
  # {Date.parse("2016-01-01") => 0.5}
  def get_personal_leave_dates(month)
    flows = self.own_flows.where("(leave_date_record like ? OR deduct_leave_date like ?) AND workflow_state = 'actived' AND (leave_date_record like '%Flow::PersonalLeave%' OR deduct_leave_date like '%Flow::PersonalLeave%')", "%#{month}%", "%#{month}%")
    records = flows.pluck(:leave_date_record).map{|record| record[month]}.compact
    deduct_records = flows.pluck(:deduct_leave_date).map{|record| record[month]}.compact

    leave_dates = (records + deduct_records).inject({}) do |result, record|
      start_date, end_date = record["start_time"].to_date, record["end_time"].to_date

      if record["vacation_days"] <= 1
        result[start_date] = record["vacation_days"]
      else
        dates = Range.new(start_date, end_date).to_a
        dates.each do |date|
          if (date == start_date && record["start_time"].include?("#{Setting.daily_working_hours.afternoon}")) || (date == end_date && record["end_time"].include?("#{Setting.daily_working_hours.afternoon}"))
            result[date] = 0.5
          else
            result[date] = 1
          end
        end
      end

      result
    end

    absence_dates = self.attendances
      .where("date_format(record_date, '%Y-%m') = ? AND record_type like ?", month, "%旷工")
      .pluck(:record_date)
      .inject({}){|result, date| result[date] = 1; result}

    leave_dates.merge(absence_dates)
  end

  # 返回某月的请假的日期
  def get_vacation_dates(month)
    flows = self.own_flows.where("(leave_date_record like ? OR deduct_leave_date like ?) AND workflow_state = 'actived'", "%#{month}%", "%#{month}%")
    records = flows.pluck(:leave_date_record).map{|record| record[month]}.compact
    deduct_records = flows.pluck(:deduct_leave_date).map{|record| record[month]}.compact

    leave_days = (records + deduct_records).inject({}) do |result, record|
      start_date = record["start_time"].to_date
      end_date = record["end_time"].to_date

      if start_date == end_date
        if Flow::WORKING_DAYS_LEAVE_FLOW.include?(record["leave_type"])
          vacation_days = VacationRecord.cals_days(
            employee_id: self.id,
            start_time: record["start_time"].to_datetime,
            end_time: record["end_time"].to_datetime,
            start_date: start_date,
            end_date: end_date,
            vacation_type: I18n.t("flow.type.#{record['leave_type']}"),
            is_contain_free_day: true
          )[:vacation_days]
        else
          vacation_days = record["vacation_days"]
        end

        if result[start_date]
          result[start_date] += vacation_days
        else
          result[start_date] = vacation_days
        end
      else
        working_dates = Range.new(start_date, end_date).to_a
        working_dates.each do |date|
          if (date == start_date && record["start_time"].include?("#{Setting.daily_working_hours.afternoon}")) || (record["end_time"].include?("#{Setting.daily_working_hours.afternoon}") && date == end_date)
            vacation_days = 0.5
          else
            vacation_days = 1
          end

          if result[date]
            result[date] += vacation_days
          else
            result[date] = vacation_days
          end
        end
      end

      result
    end

    absence_days = self.attendances
      .where("date_format(record_date, '%Y-%m') = ? AND record_type like ?", month, "%旷工")
      .pluck(:record_date)
      .inject({}){|result, date| result[date] = 1; result}

    absence_days.merge(leave_days)
  end

  # 是否全月不在岗
  # type_index标识不在岗类型，默认为0，包含请假，旷工等
  # type_index = 1, 病假、病假工伤待定、怀孕待产，判断是否全月请病假
  # 判断逻辑为：
  # 如果该员工为标准工时制的：请假天数 + 休息日 = 当月自然日
  # 其余的为：请假天数 = 当月自然日（有问题）
  # type_index=2 则包含出差、离岗培训、休假(所有假)，都是自然日
  # type_index=3 则包含产假、哺乳假、工伤假，都是自然日
  # type_index=4, 空勤停飞、病假、病假工伤待定、怀孕待产，判断是否全月请病假或停飞
  def full_month_vacation?(month, type_index = 0, special_states = nil)
    start_date = "#{month}-01".to_date
    end_date = start_date.end_of_month
    original_days = Range.new(start_date, end_date).to_a
    free_days = VacationRecord.check_free_days(start_date, end_date)
    flows = self.own_flows.where("(leave_date_record like ? OR deduct_leave_date like ?) AND workflow_state = 'actived'", "%#{month}%", "%#{month}%")
    leave_date_records = flows.pluck(:leave_date_record).map{|record| record[month]}.compact
    deduct_leave_records = flows.pluck(:deduct_leave_date).map{|record| record[month]}.compact
    records = leave_date_records + deduct_leave_records

    # 如果本月的流程中相加后的天数不为整数那么肯定不是全月不在岗
    half_days = records.inject([]) do |result, record|
      result << record["start_time"] if record["start_time"].include?("T#{Setting.daily_working_hours.afternoon}")
      result << record["end_time"] if record["end_time"].include?("T#{Setting.daily_working_hours.afternoon}")
      result
    end

    return false if half_days.group_by{|day| day}.values.map(&:count).uniq.include?(1) && type_index != 4
    case type_index
    when 0
      leave_days = records.inject([]){|days, record| days += Range.new(record["start_time"].to_date, record["end_time"].to_date).to_a; days}
      attendance_days = self.attendances.where("record_date >= ? AND record_date <= ? AND record_type like ?", start_date, end_date, "%旷工").pluck(:record_date)
      days = leave_days + attendance_days
    when 1
      days = records.inject([]){|days, record| days += Range.new(record["start_time"].to_date, record["end_time"].to_date).to_a if ["Flow::SickLeave", "Flow::SickLeaveInjury", "Flow::SickLeaveNulliparous"].include?(record["leave_type"]); days}
    when 2
      days = records.inject([]){|days, record| days += Range.new(record["start_time"].to_date, record["end_time"].to_date).to_a; days}
      days = (days + free_days) if self.master_position.schedule.try(:display_name) == "标准工时制"
      attendance_summary = self.attendance_summaries.find_by(summary_date: month)

      return (days.uniq.count + attendance_summary.evection.to_f + attendance_summary.cultivate.to_f) >= original_days.count ? true : false
    when 3
      days = records.inject([]){|days, record| days += Range.new(record["start_time"].to_date, record["end_time"].to_date).to_a if ["Flow::OccupationInjury", "Flow::LactationLeave", "Flow::MaternityLeave"].include?(record["leave_type"]); days}
    when 4
      hash_days = self.get_sick_leave_and_state_dates(records, special_states, month)
      return false if hash_days.select{|k,v| v.to_i != v}.count > 0
      days = hash_days.keys
    end

    days = (days + free_days) if self.master_position.schedule.try(:display_name) == "标准工时制"
    days.sort{|i, j| i <=> j}.uniq == original_days ? true : false
  end

  def get_sick_leave_and_state_dates(records, special_states, month)
    start_date = "#{month}-01".to_date
    end_date = start_date.end_of_month

    hash_days = records.inject({}) do |hash_days, record|
      if ["Flow::SickLeave", "Flow::SickLeaveInjury", "Flow::SickLeaveNulliparous"].include?(record["leave_type"])
        Range.new(record["start_time"].to_date, record["end_time"].to_date).each do |date|
          next if date.end_of_month != end_date
          if (date == record["start_time"].to_date && record["start_time"].include?(Setting.daily_working_hours.afternoon)) || (date == record["end_time"].to_date && record["end_time"].include?(Setting.daily_working_hours.afternoon))
            if date == record["start_time"].to_date
              standard = 0.9
            else
              standard = 0.1
            end
            hash_days[date] = hash_days[date].to_f + standard
            hash_days[date] = standard if hash_days[date] == 0.2 || hash_days[date] == 1.8
          else
            hash_days[date] = 1
          end
        end
      end
      hash_days
    end

    special_states.each do |state|
      next if state.special_date_from > end_date or (state.special_date_to.present? and state.special_date_to < start_date)
      standard_start = state.special_date_from < start_date ? start_date : state.special_date_from
      standard_end = (state.special_date_to.blank? or state.special_date_to > end_date) ? end_date : state.special_date_to
      Range.new(standard_start, standard_end).to_a.uniq.each{|date| hash_days[date] = 1}
    end

    hash_days.select{|key, value| value != 1}.each{|key, value| hash_days[key] = 0.5}
    hash_days
  end

  # 连续 N 个月病假不在岗
  def is_continus_sick_leave_month(month, special_states = nil, number = 7)
    @current_month = Date.parse(month + '-01')
    @months = [month]

    (number - 1).downto(1) do |_|
      @current_month = @current_month.prev_month
      @months.unshift(@current_month.strftime("%Y-%m"))
    end

    @months.map{|m|self.full_month_vacation?(m, 4, special_states)}.select{|x|x}.size >= number
  end

  # 是否空勤转地面工作的时限内
  # 空勤转地面次月后返回true值，异动的结束日期可能为空(目前是派驻结束日期不能为空)
  def is_stop_fly_to_land?(month)
    start_date = Date.parse(month + "-01").prev_month.beginning_of_month
    end_date = Date.parse(month + "-01").prev_month.end_of_month

    @states = SpecialState.where(employee_id: self.id, special_category: '空勤地面')

    @states.each do |state|
      return true if state.special_date_from <= start_date && !state.special_date_to
      return true if state.special_date_from <= start_date && state.special_date_to >= end_date
    end

    false
  end

  # 处于空勤通道的是否没有参与飞行
  def is_unfly?(month)
    hours_fees = self.hours_fees.where(month: month)
    hours_fees.each{|h| return false if h.fly_hours && h.fly_hours.to_f > 0} if hours_fees.present?
    true
  end

  # 返回请假描述，用在薪酬计算备注列和导出表当中
  # {"病假" => "2015-09-12 到 2015-09-15 请假 XX 天"}
  # 是否包含休息日, 根据假别自动判断
  # vacation_type 假别名称
  def get_vacation_desc(month, vacation_type = nil)
    exclude_leave_types = %w(Flow::AnnualLeave Flow::FuneralLeave Flow::MarriageLeave Flow::OccupationInjury Flow::MaternityLeave Flow::LactationLeave Flow::PrenatalCheckLeave Flow::WomenLeave Flow::RearNurseLeave)
    flows = self.own_flows.where("(leave_date_record like ? OR deduct_leave_date like ?) AND workflow_state = 'actived' AND type not in (?)", "%#{month}%", "%#{month}%", exclude_leave_types)
    attendances = self.attendances.where("date_format(record_date, '%Y-%m') = ? AND is_delete = ?", month, false)
    leave_date_records = flows.pluck(:leave_date_record).map{|record| record[month]}.compact
    deduct_leave_records = flows.pluck(:deduct_leave_date).map{|record| record[month]}.compact
    records = leave_date_records + deduct_leave_records
    records = records.select{|record| I18n.t("flow.type.#{record['leave_type']}") == vacation_type}.compact if vacation_type
    result = {}

    records.each do |record|
      key = I18n.t("flow.type.#{record['leave_type']}")

      if result[key]
        result[key] += "#{record['start_time'].to_date} 到 #{record['end_time'].to_date}请#{key}#{record['vacation_days']}天; "
      else
        result[key] = "#{record['start_time'].to_date} 到 #{record['end_time'].to_date}请#{key}#{record['vacation_days']}天; "
      end
    end

    attendances.each do |attendance|
      key = attendance.record_type =~ /(迟到|早退)$/ ? "迟到早退" : "旷工"

      if result[key]
        result[key] += "#{key}: #{attendance.record_date}; "
      else
        result[key] = "#{key}: #{attendance.record_date}; "
      end
    end

    result
  end

  # 是否认定是实习生
  def is_trainee?
    # 蓝天劳务(实习) && 骐骥劳务(实习)
    self.labor_relation.try(:display_name).try(:include?, "实习")
  end

  def is_service_a?
    self.try(:channel).try(:display_name).to_s == '服务A'
  end

  def last_merged_contract
    self.contracts.where(original: false).order(start_date: "asc").last
  end

  # 判断学历信息是否发生改变
  def has_changed_education?(hash)
    return (hash[:education_background_id] != self.education_background_id) || (hash[:graduate_date] != self.graduate_date) || (hash[:school] != self.school) || (hash[:major] != self.major)
  end

  def change_info_by_contract(contract)
    labor_relation_id = Employee::LaborRelation.find_by(display_name: contract.apply_type).id

    hash = {}

    if contract.apply_type == "合同"
      hash[:labor_relation_id] = labor_relation_id
      hash[:change_contract_date] = contract.start_date
    elsif contract.apply_type == '合同制'
      hash[:labor_relation_id] = labor_relation_id
      hash[:change_contract_system_date] = contract.start_date
    end

    self.update(hash)
    ChangeRecord.save_record('employee_update', self).send_notification
    ChangeRecordWeb.save_record('employee_update', self).send_notification
  end

  private
  def encrypt_password
    self.crypted_password = ::BCrypt::Password.create(self.password || DEFAULT_PASSWORD)
  end

  def password_required
    crypted_password.blank? || self.password.present?
  end

  def create_contact_and_personal_info
    unless self.contact
      contact = self.build_contact
      contact.save_without_auditing
    end
    unless self.personal_info
      personal_info = self.build_personal_info
      personal_info.save_without_auditing
    end
  end

  def clear_salary_person_setup
    @setup = self.salary_person_setup
    if @setup
      attributes = SalaryPersonSetup.attribute_names.delete_if{|n| %(id employee_id is_stop created_at updated_at).include?(n)}
      attributes.each do |attribute|
        @setup.send(attribute + '=', nil)
      end
      @setup.save
    end
  end

  # def set_employee_no
  #   if self.employee_no.nil?
  #     employee_no = Employee.last ? (Employee.last.employee_no.to_i + 1).to_s : '1'
  #     self.employee_no = employee_no.insert(0, '0' * (6 - employee_no.size))
  #   end
  # end

  def self.virtual_list
    Employee.unscoped.where(is_virtual: true).map(&:id)
  end

  def self.hr_department_id
    Department.find_by(name: '人力资源部').id
  end

  class << self
    def sort(current_id, target_id)
      current_item = self.find current_id
      current_place = current_item.sort_no
      target_item = self.find target_id
      target_place = target_item.sort_no

      if current_place > target_place
        #排序上升
        self.where(
          "department_id = ? and sort_no >= ? and sort_no < ?",\
          current_item.department_id,\
          target_place,
          current_place
        ).update_all("sort_no = sort_no + 1")
      else
        #排序下降
        self.where(
          "department_id = ? and sort_no > ? and sort_no <= ?",\
          current_item.department_id,\
          current_place,
          target_place
        ).update_all("sort_no = sort_no - 1")
      end
      #更新自己
      current_item.update(sort_no: target_place)
    end
  end
end
