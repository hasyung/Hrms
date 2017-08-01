class ChangeRecord < ActiveRecord::Base
  serialize :change_data, Hash
  serialize :ok_array, Array
  serialize :failed_array, Array

  # after_commit :send_notification

  def send_notification
    # logger.error "Error is here ~~~~~~~"
    ChangeRecordDeliverWorker.perform_async(self.id)
  end

  class << self
    def save_record(change_type, change_object, extras = {})
      obj = nil

      if %w(employee_resign employee_fire employee_retire employee_early_retire employee_outgo).include?(change_type)
        obj = save_flow_record(change_type, change_object)
      elsif %w(org_add org_delete org_modify).include?(change_type)
        obj = save_org_record(change_type, change_object)
      elsif %w(employee_update employee_newbie).include?(change_type)
        obj = save_employee_record(change_type, change_object, extras)
      elsif %w(employee_transfer employee_org employee_leader).include?(change_type)
        obj = save_pos_record(change_type, change_object, extras)
      end

      obj
    end

    def save_flow_record(change_type, change_object)
      change_data = {
        changeDate: Date.current,
        employee: get_employee_hash(change_object)
      }

      sever_labor_relation = change_type == 'employee_early_retire' ? false : true
      change_data.merge!({serverLaborRelation: sever_labor_relation})

      create(
        change_type: change_type,
        event_time: DateTime.now,
        change_data: change_data
      )
    end

    def save_org_record(change_type, hash)
      create(
        change_type: change_type,
        event_time: DateTime.now,
        change_data: hash
      )
    end

    def save_pos_record(change_type, change_object, extras)
      create(
        change_type: change_type,
        event_time: DateTime.now,
        change_data: {
          changeDate: Date.current,
          employee: get_employee_hash(change_object, extras)
        }
      )
    end

    def save_employee_record(change_type, change_object, extras)
      change_data = {
        changeDate: Date.current,
        employee: get_employee_hash(change_object, extras)
      }

      change_data.merge!({reportNo: ''}) if change_type == 'employee_newbie'

      create(
        change_type: change_type,
        event_time: DateTime.now,
        change_data: change_data
      )
    end

    def get_employee_hash(employee, extras = {})
      languages = employee.try(:languages) ? employee.languages.inject([]){|a, l| a << {l.name => l.grade} if l.try(:name).present?} : []
      {
        name:            employee.name,
        gender:          employee.gender.try(:display_name),
        national:        employee.nation,
        political:       employee.political_status.try(:display_name),
        employeeNo:      employee.employee_no,
        school:          employee.school,
        major:           employee.major,
        education:       employee.education_background.try(:display_name),
        degree:          employee.degree.try(:display_name),
        foreignLanguage: languages,
        birthday:        employee.birthday,
        address:         employee.contact.address,
        nativePlace:     employee.native_place,
        laborRelation:   employee.labor_relation.try(:display_name),
        identityNo:      employee.identity_no,
        channel:         employee.channel.try(:display_name),
        category:        employee.category.try(:display_name),
        technicalDuty:   employee.technical_duty,
        jobTitle:        employee.job_title,
        jobTitleDegree:  employee.job_title_degree.try(:display_name),
        department: {
          fullName:     employee.department.try(:full_name),
          serialNumber: employee.department.try(:serial_number)
        },
        masterPosition: {
          name: employee.master_positions.first.try(:name)
        },
        contactWay: {
          mobile:         employee.contact.mobile,
          telephone:      employee.contact.telephone,
          address:        employee.contact.address,
          mailingAddress: employee.contact.mailing_address,
          email:          employee.contact.email,
          postCode:       employee.contact.postcode
        },
        positions:           employee.employee_positions.inject([]){|a,p| a << {name: p.full_name}},
        joinScalDate:        employee.join_scal_date,
        startWorkDate:       employee.start_work_date,
        startInternshipDate: employee.start_internship_date,
        retirementDate:      employee.retirement_date,
        classification:      employee.classification,
        isDelete:            employee.is_delete,
        leaveJobDate:        employee.approve_leave_job_date || employee.early_retire_employee.try(:change_date),
        leaveJobReason:      employee.early_retire_employee ? '退养' : employee.leave_job_reason,
        fileNo: LeaveEmployee.find_by(name: employee.name, employee_no: employee.employee_no).try(:file_no) || employee.early_retire_employee.try(:file_no),
        d1SortNo:         employee.department.try(:d1_sort_no),
        d2SortNo:         employee.department.try(:d2_sort_no),
        d3SortNo:         employee.department.try(:d3_sort_no),
        sortNo:           employee.sort_no,
        dutyRank:         employee.duty_rank.try(:display_name),
        positionOaFile:   extras[:position_oa_file],
      }
    end
  end
end
