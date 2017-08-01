class ChangeRecordWeb < ActiveRecord::Base
	serialize :change_data, Hash
  serialize :ok_array, Array
  serialize :failed_array, Array


  # after_commit :send_notification

  def send_notification
    # logger.error "Error is here ~~~~~~~"
    ChangeRecordDeliverWebWorker.perform_async(self.id)
  end

  class << self
  	def save_record(change_type, change_object, extras = {})
  		obj = nil

  		if %w(employee_resign employee_retire employee_outgo employee_update employee_newbie employee_fire employee_early_retire employee_special).include?(change_type)
  			obj = employee_record(change_type, change_object)
  		elsif %w(position_create position_update position_destroy).include?(change_type)
  			obj = position_record(change_type, change_object)
  		end
  		
  		obj
  	end

  	def employee_record(change_type, change_object)
  		type = {
  			"employee_resign"       => "employee_dimission",
  			"employee_retire"       => "employee_dimission",
  			"employee_outgo"        => "employee_update",
  			"employee_update"       => "employee_update",
  			"employee_newbie"       => "employee_create",
  			"employee_fire"         => "employee_dimission",
  			"employee_early_retire" => "employee_dimission",
  			"employee_special"      => "employee_special"
  		}


		status = "0" if type[change_type] == "employee_create"
		status = "1" if type[change_type] == "employee_update"
		status = "2" if type[change_type] == "employee_dimission"
		status = "3" if type[change_type] == "employee_special"


  		ChangeRecordWeb.create(
  			change_type: type[change_type],
        event_time: DateTime.now,
        change_data:  get_employee(change_object, status)

  		)
  	end

  	def position_record(change_type, change_object)

    		ChangeRecordWeb.create(
    			change_type: change_type,
          event_time: DateTime.now,
          change_data: get_position(change_object)
    		)
  	end

  	private
  	def get_employee(employee, status, extras = {})
  		languages = employee.languages.inject([]) do |names, language|
  			names << {glbdef1: language.id.to_s || "", glbdef2: language.name || "",glbdef3: language.grade || "",status: status} if language.name && language.grade

      	names
  		end

  		family_members = employee.family_members.inject([]) do |members, family_member|

  			members << {glbdef1: family_member.id.to_s || "", glbdef2: family_member.name || "", glbdef3: family_member.birthday || "", glbdef4: family_member.company || "", glbdef5: family_member.native_place || "", status: status}
  			members
  		end

  		technical_records = employee.technical_records.inject([]) do |records, technical_record|
  			records << {glbdef1: technical_record.id.to_s || "", glbdef2: technical_record.technical || "", glbdef3: technical_record.change_date || "", glbdef4: technical_record.file_no || "", status: status}

  			records
  		end
  		{
		    psndoc: {
		        code:              employee.employee_no.to_s,
		        name:              employee.name.to_s,
		        id:                employee.identity_no.to_s,
		        sex:               employee.gender.try(:display_name) || "", 
		        joinworkdate:      employee.start_work_date || "",
            birthdate:         employee.birthday || "",
            nationality:       employee.nation || "",
            polity:            employee.political_status.try(:display_name) || "",
            mobile:            employee.contact.try(:mobile) || "",
		        officephone:       employee.contact.try(:telephone) || "",
            email:             employee.contact.try(:email) || "",
		        glbdef1:           employee.id.to_s,
		        glbdef2:           employee.probation_months || "", 
		        glbdef3:           employee.change_contract_date || "",
		        glbdef5:           employee.employee_positions.where("employee_positions.sort_index = 0").first.try(:category) || "", 
		        glbdef6:           employee.category.try(:display_name) || "", 
		        glbdef7:           employee.channel.try(:display_name) || "", 
		        glbdef8:           employee.classification || "", 
		        glbdef9:           employee.duty_rank.try(:display_name) || "", 
		        glbdef10:          employee.labor_relation.try(:display_name) || "", 
		        glbdef11:          employee.employment_status.try(:display_name) || "", 
		        glbdef12:          employee.location || "", 
		        glbdef13:          employee.position_remark || "", 
		        glbdef14:          employee.technical || "",
            glbdef15:          employee.nationality || ""
		    }, 
		    psnjob: {
		        clerkcode:         employee.employee_no.to_s,
		        pk_dept:           employee.department.id.to_s,
		        pk_post:           employee.master_position.try(:id).to_s,
		        begindate:         status == '2' ?  employee.approve_leave_job_date : status == '3' ? Time.new.strftime("%Y-%m-%d") : employee.work_experiences.where("`end_date` = '至今' and position like '%主职%'").first.try(:start_date).to_s || "",
		        jobglbdef1:        employee.employee_positions.where('employee_positions.category = "主职" and employee_positions.sort_index = 0').first.try(:id).to_s,
		        jobglbdef2:        employee.start_internship_date.to_s
		    }, 
		    psnedu: {
		        enddatet:          employee.education_experiences.order(graduation_date: :desc).first.try(:graduation_date) || "", 
		        education:         employee.education_background.try(:display_name) || "", 
		        pk_degree:         employee.degree.try(:display_name).to_s,
		        glbdef1:           employee.education_background.try(:id).to_s

		    }, 
		    psnglbdef1: languages, 
		    psnglbdef2: family_members, 
		    psnglbdef3: technical_records
		}
  	end

  	def get_position(position, extras = {})
  		{
		    postname: position.name, 
		    pk_dept: position.department.id.to_s,
			builddate: position.created_at.strftime("%Y-%m-%d"), 
			abortdate: "", 
		    glbdef1: position.id.to_s,
		    glbdef2: position.category.try(:display_name) || "", 
		    glbdef3: position.channel.try(:display_name) || "", 
		    glbdef4: position.budgeted_staffing.to_s, 
		    glbdef5: position.employees_count.to_s, 
		    glbdef6: position.schedule.try(:display_name) || "", 
		    glbdef7: position.position_nature.try(:display_name) || "", 
		    glbdef8: position.specification.try(:duty) || "", 
		    glbdef9: position.specification.try(:personnel_permission) || "", 
		    glbdef10: position.specification.try(:financial_permission) || "", 
		    glbdef11: position.specification.try(:business_permission) || "", 
		    glbdef12: position.specification.try(:superior) || "", 
		    glbdef13: position.specification.try(:underling) || "", 
		    glbdef14: position.specification.try(:internal_relation) || "", 
		    glbdef15: position.specification.try(:external_relation) || "", 
		    glbdef16: position.specification.try(:qualification) || ""

		}
  	end
  end
end
