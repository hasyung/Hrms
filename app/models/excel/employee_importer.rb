module Excel
  class EmployeeParser
    attr_reader :row, :headers, :error

    def initialize(row, headers, &block)
      @row = row
      @headers = headers
      @error = ''

      self.instance_eval(&block) if block_given?
    end

    def valid_presence_of(data, column_names)
      column_names.each do |key|
        error << "#{I18n.t('activerecord.attributes.employee.' + key.to_s.sub(/_id/, ''))}的值不能为空或在值输入有误; " if data[key].nil?
      end
    end

    def valid_uniqueness_of(data, column_names, model, employees)
      column_names.each do |key|
        next if data[key].nil?
        if model.where(key => data[key]).count > 0 or employees.select{|e| e[key] == data[key]}.size > 0
          error << "#{I18n.t('activerecord.attributes.employee.' + key.to_s.sub(/_id/, ''))}值必须唯一；"
        end
      end
    end

    def valid_position
      unless position_id
        dep_index = headers[:department]
        full_name = row[dep_index.first..dep_index.last].compact.join('-')
        position_name = row[headers[:position]]

        error << "#{full_name}下面的#{position_name}不存在；"
      end
    end

    def valid?
      error == ''
    end

    def employee_data
      data ||= {
        name: row[headers[:name]].strip,
        identity_name: row[headers[:name]].strip.gsub(/[0-9a-zA-Z]/, ''),
        employee_no: row[headers[:employee_no]],
        category_id: CodeTable::Category.find_by(display_name: (row[headers[:category]] || '员工')).id,
        channel_id: CodeTable::Channel.find_by(display_name: row[headers[:channel]]).try(:id),
        classification: row[headers[:classification]],
        location: row[headers[:location]] || "成都",
        labor_relation_id: Employee::LaborRelation.find_by(display_name: row[headers[:labor_relation]]).try(:id),
        duty_rank_id: Employee::DutyRank.find_by(display_name: row[headers[:duty_rank]]).try(:id),
        gender_id: CodeTable::Gender.find_by(display_name: row[headers[:gender]]).try(:id),
        nationality: (row[headers[:nationality]] || "中国"),
        nation: (row[headers[:nation]] || (row[headers[:nationality]] == "中国" ? "汉族" : nil)),
        birthday: row[headers[:birthday]],
        identity_no: row[headers[:identity_no]],
        education_background_id: CodeTable::EducationBackground.find_by(display_name: education_background_data).try(:id),
        start_work_date: row[headers[:start_work_date]],
        join_scal_date: row[headers[:join_scal_date]],
        job_title: row[headers[:job_title]],
        job_title_degree_id: Employee::JobTitleDegree.find_by(display_name: row[headers[:job_title_degree]]).try(:id),
        political_status_id: CodeTable::PoliticalStatus.find_by(display_name: (row[headers[:political_status]] || '群众')).id,
        native_place: row[headers[:native_place]],
        start_internship_date: row[headers[:start_internship_date]],
        probation_months: row[headers[:probation_months]],
        school: row[headers[:school]],
        major: row[headers[:major]],
        graduate_date: (row[headers[:graduate_date]] if row[headers[:graduate_date]].class == Date),
        position_remark: row[headers[:position_remark]],
        technical_duty: row[headers[:technical_duty]],
        degree_id: CodeTable::Degree.find_by(display_name: row[headers[:degree]]).try(:id),
        old_employee_no: row[headers[:old_employee_no]]
      }
    end

    def contact_data
      address = row[headers[:employee_contact_way_address]]
      mobile = row[headers[:employee_contact_way_mobile]]

      if address || mobile
        {address: address, mobile: mobile }
      else
        {}
      end
    end

    def language_data
      return [] unless row[headers[:language]]

      languages = row[headers[:language]].split('/')
      languages.inject([]) do |result, language|
        language.gsub!(/：/, ":")

        if language.include?(":")
          language_attr = language.split(':')
          result << {name: language_attr.first, grade: language_attr.last}
        else
          result << {name: "英语", grade: language}
        end

        result
      end
    end

    def position_data
      data ||= { position_id: position_id }
    end

    def position_id
      position = Position.where(name: row[headers[:position]])

      if position.count > 0
        pos = map_department_for(row[headers[:position]])
        pos.nil? ? nil : pos.id
      else
        nil
      end
    end

    def map_department_for(position_name)
      index = headers[:department]
      full_name = row[index.first..index.last].compact.join('-')
      department = Department.find_by(full_name: full_name)

      return nil if department.nil?
      department.positions.find_by(name: position_name)
    end

    def education_background_data
      val = row[headers[:education_background]]

      case val
      when "本科"
        val = "全日制本科"
      when "小学", "初中", "高中", "中专", "职高"
        val = "大专以下"
      else
        val
      end
    end
  end

  class EmployeeValidator
    attr_reader :row, :headers, :error

    def initialize(row, headers, &block)
      @row = row
      @headers = headers
      @error = ''

      self.instance_eval(&block) if block_given?
    end

    def valid?
      error == ''
    end

    def valid_presence_of(column_names)
      column_names.each do |key|
        unless row[headers[key]]
          error << "#{I18n.t('activerecord.attributes.employee_contact_way.' + key.to_s.sub(/^employee_contact_way_/, ''))}不能为空;" and next if key.to_s =~ /^employee_contact_way/
          error << "#{I18n.t('activerecord.attributes.employee.' + key.to_s)}不能为空;"
        end
      end
    end

    def valid_type_of(column_names, types)
      column_names.each do |key|
        val = row[headers[key]]
        next if val.nil?
        unless types.include?(val.class)
          error << "#{I18n.t('activerecord.attributes.employee_contact_way.' + key.to_s.sub(/^employee_contact_way_/, ''))}的数据类型错误;" and next if key.to_s =~ /^employee_contact_way/
          error << "#{I18n.t('activerecord.attributes.employee.' + key.to_s)}的数据类型错误;"
        end
      end
    end
  end

  class EmployeeImporter
    attr_reader :errors, :employee_data, :sheet, :warns

    def initialize(file_path)
      @sheet = Spreadsheet.open(file_path).worksheet(0)
      @errors = []
      @employee_data = []
    end

    def import
      Employee.transaction do
        @employee_data.each do |params|
          puts params[:employee]
          employee = Employee.new(params[:employee])
          employee.save_without_auditing
          contact = employee.contact || employee.build_contact
          contact.assign_attributes(params[:contact])
          contact.save_without_auditing

          position = Position.find(params[:position_id])
          employee_position = position.employee_positions.new(employee_id: employee.id, category: '主职')
          employee_position.save_without_auditing
          employee_position.generate_work_experience(employee.join_scal_date, 1)
          employee.fix_sort_no_and_department_id(position.department_id)

          employee.create_salary_person_setup!
          ChangeRecord.save_record('employee_newbie', employee).send_notification
          ChangeRecordWeb.save_record('employee_newbie', employee).send_notification

          department_root_id = employee.department.parent_chain.first.id
          summary_date = Date.today.strftime("%Y-%m")
          attendance_summary_status_manager = AttendanceSummaryStatusManager.find_by(department_id: department_root_id, summary_date: summary_date)

          unless attendance_summary_status_manager.department_hr_checked
            attendance_summary_status_manager.attendance_summaries.create(
              employee_id:       employee.id,
              employee_name:     employee.name,
              employee_no:       employee.employee_no,
              department_id:     employee.department_id,
              department_name:   employee.department.full_name,
              labor_relation:    employee.labor_relation.display_name,
              summary_date:      summary_date
            )
          end
        end
      end
    end

    def has_errors?
      return true if @errors.count > 0
    end

    def parse_data
      @sheet.each_with_index do |row, index|
        next if index == 0
        row = strip_row(row)
        puts "解析#{index}行"
        next unless row_validate?(row, index)

        parser = parse_row(row, index, @employee_data)
        next unless parser
        @employee_data << employee_params(parser)
      end
    end

    def employee_params(data)
      {
        employee: data.employee_data.merge(languages_attributes: data.language_data),
        position_id: data.position_id,
        contact: data.contact_data
      }
    end

    def row_validate?(row, index)
      validator = EmployeeValidator.new(row, headers) do
        valid_presence_of([:employee_no, :name, :labor_relation, :gender, :birthday])
        valid_type_of([:employee_no, :identity_no, :employee_contact_way_mobile], [String])
        valid_type_of([:birthday, :join_scal_date, :start_work_date], [Date, DateTime])
      end

      if validator.valid?
        return true
      else
        errors << ("#{index}行：" + validator.error)
        return false
      end
    end

    def parse_row(row, index, employees)
      parser = EmployeeParser.new(row, headers) do
        valid_position
        valid_presence_of(employee_data, [:employee_no, :name, :labor_relation_id, :gender_id, :birthday])
        valid_uniqueness_of(employee_data, [:employee_no], Employee, employees)
      end

      if parser.valid?
        return parser
      else
        errors << ("#{index}行: " + parser.error) and return false
      end
    end

    def strip_row(row)
      strip_index.each do |index|
        row[index] = row[index].to_s.strip if row[index] && row[index].instance_of?(String)
      end

      row
    end

    def strip_index
      [0, 1, 2, 3, 7, 8, 11, 13, 14, 16, 20, 36]
    end

    def headers
      {
        department: [0, 1, 2, 3],
        position: 11,
        position_remark: 12,
        name: 4,
        old_employee_no: 5,
        employee_no: 6,
        category: 7,
        channel: 8,
        classification: 9,
        location: 13,
        labor_relation: 14,
        duty_rank: 15,
        gender: 16,
        nationality: 17,
        nation: 18,
        birthday: 19,
        identity_no: 20,
        education_background: 21,
        degree: 23,
        start_work_date: 24,
        join_scal_date: 25,
        job_title: 28,
        job_title_degree: 29,
        technical_duty: 30,
        political_status: 31,
        language: 37,
        native_place: 41,
        school: 34,
        major: 35,
        graduate_date: 36,
        employee_contact_way_address: 42,
        employee_contact_way_mobile: 43,
        start_internship_date: 27,
        probation_months: 26
      }
    end
  end
end
