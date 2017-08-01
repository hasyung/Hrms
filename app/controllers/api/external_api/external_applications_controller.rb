class Api::ExternalApi::ExternalApplicationsController < ExternalController
  before_filter :check_params, only: [:execute]

  def execute
    external_service = FetchExternalService.new(params)
    @data, @code_message = external_service.send("fetch_#{params[:callName].downcase}")

    @data = @data.paginate_external(params[:callName].downcase) if @data
    result = get_data_json(params[:callName].downcase, @data)
    valid_code = Digest::MD5.hexdigest(URI::encode(result.to_s) + @external.api_secret)

    @code_message ||= {}
    render json: {code: @code_message[:code] || '0', message: @code_message[:message] || '成功', validCode: valid_code, data: result}
  end

  def push
    @external = ExternalApplication.find_by(api_key: params[:apiKey])

    message = '无符合条件的数据'
    if @external.blank?
      message ='未知的错误'
    else
       if @external.push_url.blank?
         message = '推送地址为空';
       else
         begin
           if @external.push_type == 1
             @change_record = ChangeRecordWeb.where(change_type: params[:changeType]).order(created_at: 'desc').first
             if @change_record.blank?
               message = '没有数据'
             else
               ChangeRecordDeliverWebWorker.perform_async(@change_record.id, [@external.id],true)
               message = '推送成功'
             end
           else
             @change_record = ChangeRecord.where(change_type: params[:changeType]).order(created_at: 'desc').first
             if @change_record.blank?
               message = '没有数据'
             else
               ChangeRecordDeliverWorker.perform_async(@change_record.id, [@external.id],true)
               message = '推送成功'
             end
           end
         rescue => ex
           message =  ex.to_s
         end

       end
    end
    render json: {messages: message}
  end

  def receive
    render json: {message: '推送成功'}
  end

  private
  def check_params
    error_code, message = 0, ''
    @external = ExternalApplication.find_by(api_key: params[:apiKey])
    ip = Socket.ip_address_list.detect{|intf|intf.ipv4_private?}
    ip_address = ip.ip_address if ip
    ip_address = request.remote_ip if ip_address.blank?

    if params[:apiKey].blank? || params[:signature].blank? || params[:callName].blank? || params[:requestTime].blank?
      error_code, message = -10004, '缺少业务调用名称参数'
    elsif params[:version].blank?
      error_code, message = -10003, '缺少版本参数'
    elsif @external.check_time && (Time.now.to_i - params[:requestTime].to_i > 10000)
      error_code, message = -10007, '请求超时'
    elsif @external.blank?
      error_code, message = -10001, '外接应用未注册'
    elsif @external.check_ip && (ip_address.blank? || @external.client_ips.exclude?(ip_address))
      error_code, message = -10002, "ip地址 #{ip_address} 未授权"
    elsif @external.check_signature && params[:signature] != get_signature_params(@external.api_secret)
      error_code, message = -10005, '请求签名错误'
    end

    return render json: {code: error_code.to_s, message: message} if error_code != 0
  end

  def get_signature_params(api_secret)
    Digest::MD5.hexdigest(URI::encode(params.permit(:apiKey, :version, :callName, :requestTime, :count, :lastId,
      :fetchAll, :orgNumber, :changeType, :startTime, :endTime, :employeeNo, :telephone, :mobile,:year,:category).inject([]){|arr, val|arr << val[0].to_s +
      val[1].to_s}.sort.join('')) + api_secret)
  end

  def get_data_json(callName, data)
    result = []
    case callName
    when 'department'
      result = data.inject([]) do |arr, department|
        arr << {
          id:       department.id,
          parentId: department.parent_id,
          d1SortNo: department.d1_sort_no,
          d2SortNo: department.d2_sort_no,
          d3SortNo: department.d3_sort_no,
          name: department.name,
          fullName: department.full_name,
          serialNumber: department.serial_number,
          grade: {
            level: department.grade.try(:level),
            displayName: department.grade.try(:display_name)
          },
          nature: {
            name: department.nature.try(:display_name)
          }
        }
      end
    when 'employee'
      result = data.inject([]) do |arr, employee|
        languages = employee.try(:languages) ? employee.languages.inject([]){|a, l| a << {l.name => l.grade} if l.try(:name).present?} : []
        contact = employee.contact
        work_experiences = employee.work_experiences
        education_experiences = employee.education_experiences
        family_members = employee.family_members

        arr << {
          name:              employee.name,
          gender:            employee.gender.try(:display_name),
          national:          employee.nation,
          political:         employee.political_status.try(:display_name),
          employeeNo:        employee.employee_no,
          school:            employee.school,
          major:             employee.major,
          birthPlace:        employee.birth_place,
          education:         employee.education_background.try(:display_name),
          degree:            employee.degree.try(:display_name),
          foreignLanguage:   languages,
          birthday:          employee.birthday,
          address:           employee.contact.address,
          nativePlace:       employee.native_place,
          laborRelation:     employee.labor_relation.try(:display_name),
          identityNo:        employee.identity_no,
          channel:           employee.channel.try(:display_name),
          category:          employee.category.try(:display_name),
          technicalDuty:     employee.technical_duty,
          jobTitle:          employee.job_title,
          jobTitleDegree:    employee.job_title_degree.try(:display_name),
          department: {
            fullName:       employee.department.try(:full_name),
            serialNumber:   employee.department.try(:serial_number)
          },
          masterPosition: {
            name: employee.master_positions.first.try(:name)
          },
          contactWay: {
            telephone:        contact.telephone,
            mobile:           contact.mobile,
            address:          contact.address,
            mailingAddress:   contact.mailing_address,
            email:            contact.email,
            postCode:         contact.postcode,
          },
          workExperiences: work_experiences.inject([]){ |result, work|
            result << {
              startDate:        work.start_date,
              endDate:          work.end_date,
              jobDesc:          work.job_desc,
              company:          work.company,
              department:       work.department,
              employeeCategory: work.employee_category,
              position:         work.position
            }

            result
          },
          educationExperiences: education_experiences.inject([]){ |result, education|
            result << {
              school:              education.school,
              major:               education.major,
              admissionDate:       education.admission_date,
              graduationDate:      education.graduation_date,
              category:            education.category,
              witness:             education.witness,
              degree:              education.degree.try(:display_name),
              educationBackground: education.education_background.try(:display_name)
            }
            result
          },
          familyMembers: family_members.inject([]){ |result, member|
            result << {
              name:                member.name,
              nativePlace:         member.native_place,
              birthday:            member.birthday,
              startWorkDate:       member.start_work_date,
              marriedDate:         member.married_date,
              gender:              member.gender,
              nation:              member.nation,
              position:            member.position,
              company:             member.company,
              mobile:              member.mobile,
              identityNo:          member.identity_no,
              residenceBooklet:    member.residence_booklet,
              politicalStatus:     member.political_status,
              educationBackground: member.education_background,
              relationType:        member.relation_type,
              relation:            member.relation
            }
            result
          },
          positions:                employee.employee_positions.inject([]){|a, p| a << {name: p.full_name}},
          joinScalDate:             employee.join_scal_date,
          startWorkDate:            employee.start_work_date,
          startInternshipDate:      employee.start_internship_date,
          retirementDate:           employee.retirement_date,
          classification:           employee.classification,
          isDelete:                 employee.is_delete,
          leaveJobDate:             employee.approve_leave_job_date,
          leaveJobReason:           employee.leave_job_reason,
          fileNo:                   LeaveEmployee.find_by(name: employee.name, employee_no: employee.employee_no).try(:file_no) || '',
          maritalStatus:            employee.marital_status.try(:display_name),
          joinPartyDate:            employee.join_party_date,
          changeContractSystemDate: employee.change_contract_system_date,
          changeContractDate:       employee.change_contract_date,
          location:                 employee.location,
          employmentStatus:         employee.employment_status.try(:display_name),
          graduateDate:             employee.graduate_date,
          d1SortNo:                 employee.department.try(:d1_sort_no),
          d2SortNo:                 employee.department.try(:d2_sort_no),
          d3SortNo:                 employee.department.try(:d3_sort_no),
          sortNo:                   employee.sort_no,
          dutyRank:                 employee.duty_rank.try(:display_name),
          star:                     employee.star,
          technical:                employee.technical,
          techlevelClass: employee.technical_records.inject([]){ |result, record|
            result << {
              technicalLevel:              record.technical,
              techLevelchangeDate:         record.change_date,
              techLevelchangeFile:         record.file_no
            }
            result
          },          
        }
      end
    when 'change_record'
      result = data.inject([]) do |arr, change_record|
        arr << {
          changeType: change_record.change_type,
          eventTime: change_record.event_time.to_i,
          changeData: change_record.change_data
        }
      end
    when 'update_phone'
      result = {}

      when 'performance'
        if data.blank?
          result = {}
        else

           resulthash = {}
           data.inject({}) do |arr,performance|
            unless resulthash.has_key?(performance.employee_id)
                  resulthash[performance.employee_id] = {
                      employeeId: performance.employee_id,
                      employeeName: performance.employee_name,
                      employeeNo:   performance.employee_no,
                      departmentName: performance.department_name,
                      positionName:   performance.position_name,
                      channel:        performance.channel,
                      result: []
                  }
            end
            resulthash[performance.employee_id][:result] << {
                assessTime:     performance.assess_time,
                result:         performance.result.present? ? performance.result : "" ,
                sortNo:         performance.sort_no.present? ? performance.sort_no : '',
                departmentDistributeResult: performance.department_distribute_result.present? ? performance.department_distribute_result : "",
                monthDistributeBase:      performance.month_distribute_base.present? ? performance.month_distribute_base : '',
                departmentReserved:      performance.department_reserved.present? ? performance.department_reserved : "",
                categoryName:            performance.category_name.present? ? performance.category_name : "",
                assessYear:              performance.assess_year.present? ? performance.assess_year : "",
            }

           end
          result = resulthash.values
        end
    end
    result
  end

end
