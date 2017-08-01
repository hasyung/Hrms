# == Schema Information
#
# Table name: audits
#
#  id              :integer          not null, primary key
#  auditable_id    :integer
#  auditable_type  :string(255)
#  associated_id   :integer
#  associated_type :string(255)
#  user_id         :integer
#  user_type       :string(255)
#  username        :string(255)
#  action          :string(255)
#  audited_changes :text(65535)
#  version         :integer          default("0")
#  comment         :string(255)
#  remote_address  :string(255)
#  request_uuid    :string(255)
#  created_at      :datetime
#  status_cd       :integer          default("0")
#  check_date      :date
#  reason          :string(255)
#
# Indexes
#
#  associated_index              (associated_id,associated_type)
#  auditable_index               (auditable_id,auditable_type)
#  index_audits_on_created_at    (created_at)
#  index_audits_on_request_uuid  (request_uuid)
#  user_index                    (user_id,user_type)
#

class Audit < Audited::Adapters::ActiveRecord::Audit
  as_enum :status, Setting.enums.audit_status.dup.symbolize_keys, prefix: true

  after_save :save_passed_model, if: ->(cord){ cord[:status_cd] == 2}

  # Scopes
  default_scope -> {reorder('created_at DESC')}
  scope :employee_check, -> { includes(:user).where("status_cd = 1 AND (auditable_type = 'Employee' OR associated_type = 'Employee')") }
  scope :employee_record, -> { includes(:user).where("status_cd != 1 AND (auditable_type = 'Employee' OR associated_type = 'Employee')") }
  scope :positions, -> { includes(:user).where("auditable_type = 'Position' OR associated_type = 'Position'") }

  EMPLOYEE_TYPES = {
    '基本信息' => 'Employee',
    '联系方式' => 'Employee::ContactWay',
    '其它信息' => 'Employee::PersonalInfo',
    '教育经历' => 'Employee::EducationExperience',
    '家庭成员' => 'Employee::FamilyMember',
    '工作经历' => 'Employee::WorkExperience',
    '员工岗位信息' => 'EmployeePosition'
  }


  def self.save_changes model, hash
    audit = model.audits.new action: 'update', status_cd: 1
    audit.user = model
    audited_changes = {}
    hash.each do |key, value|
      audited_changes.merge!({key => [model.send(key), value]})
    end
    audit.audited_changes = audited_changes
    audit.save ? audit : nil
  end

  def self.create_with_positions positions, user
    positions.each do |position|
      audit = position.audits.new action: 'destroy'
      audit.user = user
      audit.audited_changes = position.attributes
      audit.audited_changes.delete_if{|k, v| %w(sort_no pinyin_name pinyin_index employees_count
        is_confirmed is_delete id).include?(k)}
      audit.save
    end
  end

  def change_data_foreign_key
    data = {}
    self.audited_changes.each do |key, value|
      next if key =~ /pinyin_/ || key =~ /bit_value/ || key =~ /password/ || (value.class == Array && value[0].blank? &&
        value[1].blank?) || key =~ /favicon/ || %w(old_education_data temperature_amount communicate_allowance
        is_virtual virtual_name is_admin month_distribute_base old_employee_no change_contract_date
        change_contract_system_date change_education_date).include?(key)

      if key =~ /_id/
        key = key.sub('_id', '')
        zh_key = I18n.t('activerecord.attributes.'+ self.auditable_type.constantize.table_name.chop + '.' + key)
        auditable = self.auditable_type.constantize.unscoped.find_by(id: self.auditable_id)
        mode = auditable.try(key) && auditable.send(key).kind_of?(ActiveRecord::Base) ? auditable.send(key).class.unscoped.find_by(id: value) : nil
        data.merge!({zh_key => mode.try(:display_name) || mode.try(:name)}) and next if value.class != Array
        before = auditable.try(key) ? auditable.send(key).class.unscoped.find_by(id: value[0]) : nil
        after = auditable.try(key) ? auditable.send(key).class.unscoped.find_by(id: value[1]) : nil
        value_before = before.try(:display_name) || before.try(:name)
        value_after = after.try(:display_name) || after.try(:name)
        data.merge!({zh_key => [value_before, value_after]})
      else
        data.merge!({I18n.t('activerecord.attributes.'+ self.auditable_type.constantize.table_name.chop + '.' + key) => value})
      end
    end
    data
  end

  private
  def save_passed_model
    self.audited_changes.each do |key, value|
      self.auditable.send(key + '=', value[1]) if value.class == Array

      if self.auditable.class == Employee
        ChangeRecord.save_record('employee_update', self.auditable).send_notification
        ChangeRecordWeb.save_record('employee_update', self.auditable).send_notification
      end
    end

    if(self.auditable.identity_no_changed?)
      hash = {employee_id: self.auditable_id, category: '身份证变动', indentity_no_was: self.auditable.identity_no_was}
      Publisher.broadcast_event('SOCIAL_CHANGE_INFO', hash)
    end

    self.auditable.save_without_auditing
  end
end
