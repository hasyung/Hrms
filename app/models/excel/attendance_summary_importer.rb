module Excel
  class AttendanceSummaryImporter
    attr_accessor :error, :month
    attr_reader :sheet, :datas

    def initialize(path)
      @sheet = Spreadsheet.open(path).worksheet(0)
      @month = ""
      @error = []
      @valid_format_error = []
      @datas = []
    end

    def parse_data
      sheet.each_with_index do |row, index|
        @error << "数据对应列与模板不一致" if index == 0 && row[4].to_s.exclude?("员工编号")
        @error << "数据对应列与模板不一致" if index == 1 && row[10].to_s.exclude?("去年")
        next if index == 0 || index == 1
        next if is_value_empty?(row)
      end

      return self if @error.size > 0

      employee_no_arr = []
      sheet.each_with_index do |row, index|
        next if index == 0 || index == 1
        next if is_value_empty?(row)
        @error << "第#{index+1}行,人员#{row[5]},编号#{row[4]}有重复" if employee_no_arr.include?(row[4])
        employee_no_arr << row[4]
        employee = Employee.find_by(employee_no: row[4])
        if employee.nil?
          @error << "第#{index+1}行，人员#{row[5]}不存在"
        end
      end

      return self if @error.size > 0

      sheet.each_with_index do |row, index|
        next if index == 0 || index == 1
        next if is_value_empty?(row)
        unless valid_format_for(row)
          @error = @valid_format_error
        end
      end
      
      return self if @error.size > 0
    
      sheet.each_with_index do |row, index|
        next if index == 0 || index == 1
        next if is_value_empty?(row)
        employee = Employee.find_by(employee_no: row[4])
        data = get_data_for(row, employee)
        data.merge!(employee: employee)
        valid_leave_date_for(data)
      end

      return self if @error.size > 0

      sheet.each_with_index do |row, index|
        next if index == 0 || index == 1
        next if is_value_empty?(row)
        employee = Employee.find_by(employee_no: row[4])
        data = get_data_for(row, employee)
        data.merge!(employee: employee)
        @datas << data
      end

      return self
    end


    def valid?
      @error.size == 0
    end

    def import(import_month, import_employee, department_id)
      ActiveRecord::Base.transaction do
        @datas.each do |data|
          begin
            employee = data[:employee]
            # employee.own_flows.destroy_all
            data.each do |klass, value|
              case klass
              when /^Flow/
                value.each do |item|
                	# next if employee.own_flows.where(created_at: "#{import_month}-15".to_date.."#{import_month}-14".to_date.next_month).size > 0
                	flow = klass.split('-').first.constantize.new(item)
                	flow.set_leave_params
                	flow.save!(:validate => false)
                	flow.respond_to?(:active_job) ? flow.active_job : flow.active_workflow(false)
                end
              when /^AttendanceSummary/
                attendance_summary = employee.attendance_summaries.find_by(summary_date: month)
                break if attendance_summary.nil?
                attendance_summary.update!(value)
              when /^Attendance/
                # employee.attendances.destroy_all
                # employee.attendances.where(created_at: "#{import_month}-15".to_date.."#{import_month}-14".to_date.next_month, record_type: local_headers(klass)).destroy_all
                # next if employee.attendances.where(created_at: "#{import_month}-15".to_date.."#{import_month}-14".to_date.next_month).size > 0
                value.each do |_, attendance_attr|
                  employee.attendances.create!(attendance_attr)
                end
              when /^SpecialState/
                # employee.special_states.where(special_category: local_headers(klass)).destroy_all
                # employee.special_states.where(created_at: "#{import_month}-15".to_date.."#{import_month}-14".to_date.next_month, special_category: local_headers(klass)).destroy_all
                # next if employee.special_states.where(created_at: "#{import_month}-15".to_date.."#{import_month}-14".to_date.next_month, special_category: local_headers(klass)).size > 0
                attendance_summary = employee.attendance_summaries.find_by(summary_date: month)
                break if attendance_summary.nil?
                attendance_summary.update(cultivate: '0') if klass == "SpecialState#cultivate"
                value.each do |special_state_attr|
                  special_state = SpecialState.create!(special_state_attr)
                end
              end
            end
          rescue Exception => ex
            puts ex.to_s
            raise ex
          end
        end

        if department_id == 453 || department_id == 454
        	dep = Department.find_by(id:department_id).full_name.to_s.split('-').last
        else
	        dep = Department.find_by(id:department_id).full_name.to_s.split('-').first
	    end
        manager = AttendanceSummaryStatusManager.find_by(department_name: dep, summary_date: import_month) if dep
        manager.department_hr_check(import_employee, false, Department.find_by(name: dep).try(:id)) if manager
      end
    end

    def is_value_empty?(row)
      headers.values.inject([]) do |result, index|
        result << row[index] if row[index]
        result
      end.empty?
    end

    def valid_leave_date_for(data)
      data_overlap?(data) && data_valid?(data) ? true : false
    end

    def data_valid?(data)
      women_leave = data["Flow::WomenLeave"]

      return true unless women_leave
      return true if women_leave.count == 1 && women_leave.first[:start_time].to_date == women_leave.first[:end_time].to_date
      @error << "人员#{data[:employee].name}: 女工假请假天数填写错误，只能请一天" and return false
    end

    def data_count_valid?(data)
      employee = data[:employee]
      total_days = data.inject(0) do |days, (type, value)|
        case type
        when /^Flow/
          days += value.inject(0) do |result, item|
            result += VacationRecord.cals_days(
              employee_id: employee.id,
              start_time: item[:start_time].to_datetime,
              end_time: item[:end_time].to_datetime,
              start_date: item[:start_time].to_datetime.beginning_of_day.to_date,
              end_date: item[:end_time].to_datetime.beginning_of_day.to_date,
              vacation_type: I18n.t("flow.type.#{type.split('-').first}"),
              is_contain_free_day: true
            )[:vacation_days] if item[:start_time].to_date.strftime("%Y-%m") == month

            result
          end
        when /^AttendanceSummary/
          days += value.values.sum
        when /^Attendance/
          days += value.values.flatten.count
        when /^SpecialState/
          days += value.inject(0) do |result, item|
            result += (item[:special_date_to].to_date.day - item[:special_date_from].to_date.day)
            result
          end
        end

        days
      end

      if total_days <= Date.parse("#{month}-01").end_of_month.day
        return true
      else
        @error << "人员#{employee.name}: 填写的考勤天数大于了本月的总天数"
        return false
      end
    end

    def data_overlap?(data)
      employee = data[:employee]
      prediction = true

      total_dates = data.inject([]) do |dates, (type, value)|
        case type
        when /^Flow/
          dates << value.inject([]) do |result, item|
            result << [item[:start_time], item[:end_time]]
            result
          end
        when /^SpecialState/
          dates << value.inject([]) do |result, item|
            result << [item[:special_date_from], item[:special_date_to]]
            result
          end
        end

        dates
      end.flatten.each_slice(2).to_a.sort{|item| item.first.to_date}.reverse

      total_dates.each_with_index do |date, index|
        if date.first.to_date > date.last.to_date
          @error << "人员#{employee.name}: 填写的考情日期结束时间小于开始时间"
          prediction = false and break
        end

        range_dates = Range.new(date.first.to_date, date.last.to_date).to_a
        next_date = total_dates[index + 1]
        if next_date
          next_range_dates = Range.new(next_date.first.to_date, next_date.last.to_date).to_a
          diff = range_dates & next_range_dates

          fo = false
          if diff.count > 1
            fo = true
          elsif diff.count == 1
            if date.first.to_date > next_date.first.to_date
              fo = true if date.last == next_date.first
            else
              fo = true if date.first == next_date.last
            end
          end

          if fo
            @error << "人员#{employee.name}: 填写的考勤中出现日期重叠"
            prediction = false and break
          end
        end
      end

      return prediction
    end

    def valid_format_for(row)
      name = "人员#{row[4]} "
      headers.each do |key, index|
        col_value = row[index].to_s
        next unless col_value

        col_value.gsub!(/\s+/, "")
        col_values = col_value.split(/[,|，]/)
        prediction = col_values.select do |value|
          result = value.scan(/[0-9]*\.?[0-9]+[(|（]\d+.*[~|～]\d+.*[)|）]/)
          result.empty? || result.flatten.first != value
        end.empty?
        
        if prediction
          range_dates = col_value.gsub(/[0-9]*\.?[0-9]+[(|（]/, '').gsub(/[)|）]/, '')
            .gsub(/\s/, '').split(/[,|，]/)
            .map{|item| item.split('~')}
          range_dates.each do |date_strs|
            date_strs.each do |date_str|
              begin
                @valid_format_error << "#{name}#{local_headers(key)}数据填写有误; " and break if date_str.split("-").first.to_i > Date.parse(month + '-01').next_year.next_year.year || date_str.split("-").first.to_i < Date.parse(month + '-01').prev_year.prev_year.year
                date_temp = date_str.to_date

              rescue Exception => e
                @valid_format_error << "#{name}#{local_headers(key)}填写格式有误; "
                break
              end
            end
          end
        else
          @valid_format_error << "#{name}#{local_headers(key)}填写格式有误; "
        end

        if key == "SpecialState#Station_group"
          unless col_value.split(/[，|,]/).size == row[index + 1].to_s.split(/[，|,]/).size
            @valid_format_error << "#{name}#{local_headers(key)}与驻站地点数量不匹配; "
            break
          end
        end
      end

      if @valid_format_error.length == 0
        return true
      else
        # @valid_format_error.prepend("#{name}: ")
        return false
      end
    end

    def get_data_for(row, employee)
      composed_value = headers.inject({}) do |data, (type, index)|
        value = row[index]

        if value
          case type
          when /^Flow/
            values = get_flow_value(employee, type, value)
            # binding.pry
            data[type] = values
          when /^AttendanceSummary/
            days = value.gsub(/(\(.*\)|（.*）)/, "").split(/[，|,]/).map(&:strip).map(&:to_f).sum
            key = type.sub("AttendanceSummary#", '')
            data["AttendanceSummary"] ||= {}
            data["AttendanceSummary"].merge!({key => days})
          when /^Attendance/
            values = get_attendance_value(employee, type, value)
            data["Attendance"] ||= {}
            data["Attendance"].merge!(type.sub("Attendance#", '') => values)
          when /^SpecialState/
            values = get_special_state_value(employee, type, value, row)

            data[type] = values
          end
        end

        data
      end
    end

    def get_flow_value(employee, type, value)
      striped_value = strip_value(value)
      striped_value.inject([]) do |result, item|
        start_time = (item.first =~ /下午/) ? item.first.sub(/下午/, "T#{Setting.daily_working_hours.afternoon}+08:00") : "#{item.first}T#{Setting.daily_working_hours.morning}+08:00"
        end_time = (item.last =~ /上午/) ? item.last.sub(/上午/, "T#{Setting.daily_working_hours.afternoon}+08:00") : "#{item.last}T#{Setting.daily_working_hours.afternoon_end}+08:00"

        vacation_days = VacationRecord.cals_days(
          employee_id: employee.id,
          start_time: start_time.to_datetime,
          end_time: end_time.to_datetime,
          start_date: start_time.to_datetime.beginning_of_day.to_date,
          end_date: end_time.to_datetime.beginning_of_day.to_date,
          vacation_type: I18n.t("flow.type.#{type.split('-').first}")
        )[:general_days]

        result << {
          receptor_id: employee.id,
          sponsor_id: employee.id,
          start_time: start_time.to_datetime.to_s,
          end_time: end_time.to_datetime.to_s,
          vacation_days: vacation_days,
          reason: '上传请假'
        }
        result
      end
    end

    def get_attendance_value(employee, type, value)
      striped_value = strip_value(value).map{|item| Range.new(item.first.to_date, item.last.to_date).to_a}.flatten.uniq
      striped_value.inject([]) do |result, item|
        record_type = type.sub("Attendance#", '') == 'absence' ? "旷工" : "迟到"

        result << {
          record_type: record_type,
          record_date: item,
          employee_id: employee.id
        }

        result
      end
    end

    def get_special_state_value(employee, type, value, row)
      striped_value = strip_value(value)
      index = 0
      striped_value.inject([]) do |result, item|
        striped_item = item.map{|special_date| special_date.sub(/(上午|下午)/, '')}
        special_location = nil
        special_location = row[headers[type] + 1].to_s.split(/[，|,]/)[index] if type == 'SpecialState#Station_group'

        department_name = employee.department.parent_chain.first.name
        if local_headers(type) == "派驻" && department_name != "机务工程部" && department_name != "航空医疗卫生中心" && department_name != "计划财务部"
          records = employee.special_states.where(special_category: '借调')
          # 将借调的所有日期加入到一个数组
          transfer_dates = records.inject([]) do |transfer_dates, record|
            transfer_dates << Range.new(record.special_date_from, record.special_date_to).to_a
            transfer_dates
          end.flatten
          # 判断派驻时间是否在借调时间之内
          if transfer_dates.size > 0
            Range.new(striped_item.first.to_date, striped_item.last.to_date).to_a.each do |date|
              unless transfer_dates.include?(date)
                @error << "员工#{employee.name}处于借调期间，派驻时间必须介于借调时间段之内."
                break
              end
            end
          end
        end

        result << {
          employee_id: employee.id,
          special_category: local_headers(type),
          special_date_from: Date.parse(striped_item.first),
          special_date_to: Date.parse(striped_item.last),
          special_location: special_location
        }
        index += 1
        
        result
      end
    end

    def strip_value(value)
      dates = value.gsub(/[0-9]*\.?[0-9]+[(|（]/, '').gsub(/[)|）]/, '')
        .gsub(/\s/, '').split(/[,|，]/)
        .map{|item| item.split('~')}

      self.month = dates[0][0].to_date.strftime("%Y-%m") if !dates.empty? && self.month.empty?

      dates
    end

    def local_headers(key)
      {
        "Flow::AnnualLeave-2015" => "去年年假总计",
        "Flow::AnnualLeave-2016" => "今年年假总计",
        "Flow::AnnualLeave" => "年假",
        "Flow::MarriageLeave" => "婚丧假",
        "Flow::PrenatalCheckLeave" => "产前检查假",
        "AttendanceSummary#family_planning_leave" => "计生假",
        "Flow::LactationLeave" => "哺乳假",
        "Flow::WomenLeave" => "女工假",
        "Flow::MaternityLeave" => "产假",
        "Flow::RearNurseLeave" => "生育护理假",
        "Flow::OccupationInjury" => "工伤假",
        "AttendanceSummary#recuperate_leave" => "疗养假",
        "Flow::AccreditLeave" => "派驻休假",
        "Flow::SickLeave" => "病假",
        "Flow::SickLeaveInjury" => "病假（工伤待定）",
        "Flow::SickLeaveNulliparous" => "病假（怀孕待产）",
        "Flow::PersonalLeave" => "事假",
        "Flow::HomeLeave" => "探亲假",
        "SpecialState#cultivate" => "离岗培训",
        "SpecialState#evection" => "出差",
        "Attendance#absence" => "旷工",
        "Attendance#late" => "迟到",
        "SpecialState#Flight_grounded" => "空勤停飞",
        "SpecialState#Station_group" => "驻站天数"
      }[key]
    end

    def headers
      {
        "Flow::AnnualLeave-2015" => 10,
        "Flow::AnnualLeave-2016" => 11,
        "Flow::MarriageLeave" => 12,
        "Flow::PrenatalCheckLeave" => 13,
        "AttendanceSummary#family_planning_leave" => 14,
        "Flow::LactationLeave" => 15,
        "Flow::WomenLeave" => 16,
        "Flow::MaternityLeave" => 17,
        "Flow::RearNurseLeave" => 18,
        "Flow::OccupationInjury" => 19,
        "AttendanceSummary#recuperate_leave" => 20,
        "Flow::AccreditLeave" => 21,
        "Flow::SickLeave" => 22,
        "Flow::SickLeaveInjury" => 23,
        "Flow::SickLeaveNulliparous" => 24,
        "Flow::PersonalLeave" => 26,
        "Flow::HomeLeave" => 27,
        "SpecialState#cultivate" => 28,
        "SpecialState#evection" => 29,
        "Attendance#absence" => 30,
        "Attendance#late" => 31,
        "SpecialState#Flight_grounded" => 32,
        "SpecialState#Station_group" => 34
      }
    end
  end
end