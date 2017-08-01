module Excel
  class AttendanceSummaryExporter
    attr_reader :datas, :error

    def initialize(file_path)
      @sheet = Spreadsheet.open(file_path).worksheet(0)
      @error = []
      @datas = []
    end

    def parse_data
      @sheet.each_with_index do |row, index|
        next if index == 0 || index == 1
        break unless valid_format_for(row)
        data = get_data_for(row)
        break unless data
        data.merge!(employee_name: row[5], employee_no: row[4])
        break unless valid_leave_date_for(data)
        @datas << data
      end

      self
    end


    def write_csv
	    begin
	      @datas = @datas.inject([]) do |result, data|
	        sick_flows = [data["Flow::SickLeave"], data["Flow::SickLeaveInjury"], data["Flow::SickLeaveNulliparous"]].flatten.compact

	        # annual_2015 = [data["AnnualPrev_ADD"]].flatten.compact.inject(0){|result, data| result += data[:vacation_work_days]}
	        # annual_2016 = [data["AnnualCurrent_ADD"]].flatten.compact.inject(0){|result, data| result += data[:vacation_work_days]}
	        annual_2015 = (data["AnnualPrev_ADD"].blank? ? 0 : data["AnnualPrev_ADD"].first[:vacation_work_days])
	        annual_2016 = (data["AnnualCurrent_ADD"].blank? ? 0 : data["AnnualCurrent_ADD"].first[:vacation_work_days])
	        marriage_funeral_leave_days = [data["marriage_funeral_leave_ADD"]].flatten.compact.inject(0){|result, data| result += data[:vacation_days]}
	        prenatal_check_leave_days = [data["prenatal_check_leave_ADD"]].flatten.compact.inject(0){|result, data| result += data[:vacation_days]}
	        family_plan_leave_days = [data["family_plan_leave_ADD"]].flatten.compact.inject(0){|result, data| result += data[:vacation_days]}
	        lactation_leave_days = [data["lactation_leave_ADD"]].flatten.compact.inject(0){|result, data| result += data[:vacation_days]}
	        women_leave_days = [data["women_leave_ADD"]].flatten.compact.inject(0){|result, data| result += data[:vacation_days]}
	        maternity_leave_days = [data["Flow::MaternityLeave"]].flatten.compact.inject(0){|result, data| result += data[:vacation_days]}
	        rear_nurse_leave_days = [data["rear_nurse_leave_ADD"]].flatten.compact.inject(0){|result, data| result += data[:vacation_days]}
	        injury_leave_days = [data["injury_leave_ADD"]].flatten.compact.inject(0){|result, data| result += data[:vacation_days]}
	        recuperate_leave_days = [data["recuperate_leave_ADD"]].flatten.compact.inject(0){|result, data| result += data[:vacation_days]}
	        accredit_leave_days = [data["accredit_leave_ADD"]].flatten.compact.inject(0){|result, data| result += data[:vacation_days]}
	        sick_leave_days = [data["Flow::SickLeave"]].flatten.compact.inject(0){|result, data| result += data[:vacation_days]}
	        sick_leave_injury_days = [data["Flow::SickLeaveInjury"]].flatten.compact.inject(0){|result, data| result += data[:vacation_days]}
	        sick_leave_nulliparous_days = [data["Flow::SickLeaveNulliparous"]].flatten.compact.inject(0){|result, data| result += data[:vacation_days]}
	        sick_days = sick_flows.inject(0){|result, data| result += data[:vacation_days]}
	        sick_work_days = sick_flows.inject(0){|result, data| result += data[:vacation_work_days]}
	        personal_leave_days = [data["Flow::PersonalLeave"]].flatten.compact.inject(0){|result, data| result += data[:vacation_days]}
	        personal_leave_work_days = [data["Flow::PersonalLeave"]].flatten.compact.inject(0){|result, data| result += data[:vacation_work_days]}
	        home_leave_days = [data["Flow::HomeLeave"]].flatten.compact.inject(0){|result, data| result += data[:vacation_days]}
	        home_leave_work_days = [data["Flow::HomeLeave"]].flatten.compact.inject(0){|result, data| result += data[:vacation_work_days]}
	        cultivate_days = [data["Flow::Cultivate"]].flatten.compact.inject(0){|result, data| result += data[:vacation_days]}
	        cultivate_work_days = [data["Flow::Cultivate"]].flatten.compact.inject(0){|result, data| result += data[:vacation_work_days]}
	        evection_days = [data["Flow::Evection"]].flatten.compact.inject(0){|result, data| result += data[:vacation_days]}
	        evection_work_days = [data["Flow::Evection"]].flatten.compact.inject(0){|result, data| result += data[:vacation_work_days]}
	        absenteeism_days = [data["absenteeism_ADD"]].flatten.compact.inject(0){|result, data| result += data[:vacation_days]}
	        late_or_leave_days = [data["late_or_leave_ADD"]].flatten.compact.inject(0){|result, data| result += data[:vacation_days]}
	        flight_grounded_days = [data["Flow_flight_grounded"]].flatten.compact.inject(0){|result, data| result += data[:vacation_days]}
	        flight_grounded_days_work = [data["Flow_flight_grounded"]].flatten.compact.inject(0){|result, data| result += data[:vacation_work_days]}
	        flight_grounded_work_days = [data["Flow_flight_grounded_work"]].flatten.compact.inject(0){|result, data| result += data[:vacation_days]}
	        station_group_days = [data["Station_group_ADD"]].flatten.compact.inject(0){|result, data| result += data[:vacation_days]}

	        result << [data["fengongsi"], data["yizheng"], data["yifu"], data["erzheng"], data[:employee_no], 
	        	data[:employee_name], data["labor_relation"], data["start_working_date"], data["join_scal_date"],
	        	data["channel"], annual_2015, annual_2016, marriage_funeral_leave_days, 
	          prenatal_check_leave_days, family_plan_leave_days, lactation_leave_days, women_leave_days, maternity_leave_days, 
	          rear_nurse_leave_days, injury_leave_days, recuperate_leave_days, accredit_leave_days, sick_leave_days, 
	          sick_leave_injury_days, sick_leave_nulliparous_days, sick_days, sick_work_days, personal_leave_days, 
	          personal_leave_work_days, home_leave_days, home_leave_work_days, cultivate_days, cultivate_work_days, evection_days, 
	          evection_work_days, absenteeism_days, late_or_leave_days, flight_grounded_days, flight_grounded_days_work, 
	          flight_grounded_work_days, station_group_days, data["Station_group_space"], data["remark"]]
	        result
	      end.unshift(["分公司", "一正部门", "一副部门", "二正部门", "员工编号", "姓名", "用工性质", "参工时间", "到岗时间", "通道", 
	      	"去年年假总计", "今年年假总计", "婚丧假", "产前检查假", "计生假", "哺乳假", "女工假", "产假", "生育护理假", "工伤假", 
	      	"疗养假", "派驻休假", "病假", "病假（工伤待定）", "病假（怀孕待产）", "病假总计", "病假工作日", "事假", "事假工作日", "探亲假", 
	      	"探亲假工作日", "培训", "培训工作日", "出差", "出差工作日", "旷工", "早退迟到", "空勤人员停飞", "空勤人员停飞工作日", 
	      	"空勤人员停飞从事地面工作", "驻站天数", "驻站地点", "备注"])
	    rescue Exception => ex
	      puts ex.to_s
        raise ex
      end

      filename = "考勤表#{Time.now.to_s(:db)}.xls"
      file_path = "#{Rails.root}/public/export/tmp/#{filename}"
      head = "EF BB BF".split(' ').map{|a|a.hex.chr}.join()

      content = CSV.generate(csv = head) do |csv|
        @datas.each do |data|
          csv << data
        end
      end

      File.open(file_path, 'wb') do |f|
        f.write(content)
      end

	    {
	      path: Setting.upload_url + "/export/tmp/#{filename}",
	      filename: filename
	    }
	  end


	  def valid_leave_date_for(data)
	    data_overlap?(data) ? true : false
	  end

	  def data_overlap?(data)
	    employee_name = data[:employee_name]
	    prediction = true

	    total_dates = data.inject([]) do |dates, (type, value)|
	      case type
	      when /^Flow/
	        dates << value.inject([]) do |result, item|
	          result << [item[:start_time], item[:end_time]]
	          result
	        end
	      end

	      dates
	    end.flatten.each_slice(2).to_a.sort{|item| item.first.to_date}.reverse

	    total_dates.each_with_index do |date, index|
	    	if date.first.to_date > date.last.to_date
	        error << "人员#{employee_name}: 填写的考情日期结束时间小于开始时间"
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
	        	if date.first >= next_date.first && date.last >= next_date.last
	        		fo = true if date.first != next_date.last
	        	elsif date.first <= next_date.first && date.last <= next_date.last
	        		fo = true if date.last != next_date.first
	        	end
	        end

	        if fo
	          @error << "人员#{employee_name}: 填写的考勤中出现日期重叠"
	          prediction = false and break
	        end
	      end
	    end

	    return prediction
	  end

	  def get_data_for(row)
	  	employee_name = row[5]
	    composed_value = headers.inject({}) do |data, (type, index)|
	      value = row[index]
	      if value
	        # case type
	        # when /_ADD$/
	        #   value = get_annual_value(type, value)
	        #   data[type] = value
	        # when /^Flow/
	        values = []
	        begin
          	values = get_flow_value(type, value)
          rescue Exception => e
          	puts e.to_s
          	puts e.backtrace
            @error << "人员#{employee_name}: 日期填写格式有误"
            return false
          end
          total_days = get_annual_value(type, value)
          if type =~ /Annual/
          	if values.present? && values.first[:vacation_days] != total_days
          		@error << "人员#{employee_name}: 填写的考勤天数与考勤日期不一致"
	          	return false
          	end
          else
	          if values.present? && values.compact.inject(0){|result, data| result += data[:vacation_days]} != total_days
	          	@error << "人员#{employee_name}: 填写的考勤天数与考勤日期不一致"
	          	return false
	          end
	        end
          data[type] = values
	        # end
	      end

	      data
	    end
	    composed_value.merge!("fengongsi" => row[0])
	    composed_value.merge!("yizheng" => row[1])
	    composed_value.merge!("yifu" => row[2])
	    composed_value.merge!("erzheng" => row[3])
	    composed_value.merge!("labor_relation" => row[6])
	    composed_value.merge!("start_working_date" => row[7])
	    composed_value.merge!("join_scal_date" => row[8])
	    composed_value.merge!("channel" => row[9])

	    composed_value.merge!("Station_group_space" => row[35])
	    composed_value.merge!("remark" => row[36])
	  end

	  def get_annual_value(type, value)
	    value.split(/[,|，]/)
	      .map{|val| val.gsub(/[(|（]\d+.*[~|～]\d+.*[)|）]/, '')}
	      .map(&:to_f)
	      .sum
	  end

	  def get_flow_value(type, value)
	    striped_value = strip_value(value)
	    striped_value.inject([]) do |result, item|
	      start_time = (item.first =~ /下午/) ? item.first.sub(/下午/, "T#{Setting.daily_working_hours.afternoon}+08:00") : item.first.sub(/上午/, "") + "T#{Setting.daily_working_hours.morning}+08:00"
	      end_time = (item.last =~ /上午/) ? item.last.sub(/上午/, "T#{Setting.daily_working_hours.afternoon}+08:00") : item.last.sub(/下午/, "") + "T#{Setting.daily_working_hours.afternoon_end}+08:00"
	      start_date_str = start_time.to_date.strftime("%Y-%m-%d")
	      end_date_str   = end_time.to_date.strftime("%Y-%m-%d")
			  original_total_days = 0
			  vacation_work_days = 0
			  if type =~ /Annual/
	      	# original_total_days = record[:vacation_days]
	       #  vacation_work_days = record[:working_days]
	      	original_total_days = get_annual_value(type, value)
	      	vacation_work_days = get_annual_value(type, value)
	      else
	      	free_days = VacationRecord.check_free_days(start_time.to_date, end_time.to_date)
	      	original_total_days = (end_time.to_datetime - start_time.to_datetime).to_i + 1
	      	vacation_work_days = original_total_days - free_days.size
			    # 处理半天的情况
			    if start_time >= Time.parse("#{start_date_str}T#{Setting.daily_working_hours.afternoon}.000+08:00")
			      vacation_work_days = vacation_work_days - 0.5 if vacation_work_days > 0 unless free_days.include?(start_time.to_date)
			      original_total_days = original_total_days - 0.5 if original_total_days > 0
			    end
			    if end_time > Time.parse("#{end_date_str}T#{Setting.daily_working_hours.morning}.000+08:00") && end_time <= Time.parse("#{end_date_str}T#{Setting.daily_working_hours.afternoon}.000+08:00")
			      vacation_work_days = vacation_work_days - 0.5 if vacation_work_days > 0 unless free_days.include?(end_time.to_date)
			      original_total_days = original_total_days - 0.5 if original_total_days > 0
			    end
	      end
	      result << {
	        vacation_days: original_total_days,
	        vacation_work_days: vacation_work_days,
	        start_time: start_time,
	        end_time: end_time
	      }
	      result
	    end
	  end

	  def get_special_state_value(type, value)
	    striped_value = strip_value(value)
	    striped_value.inject([]) do |result, item|
	      striped_item = item.map{|special_date| special_date.sub(/(上午|下午)/, '')}
	      start_date, end_date = Date.parse(striped_item.first), Date.parse(striped_item.last)
	      special_days = Range.new(start_date, end_date).to_a
	      free_days = VacationRecord.send(:check_free_days, start_date, end_date)

	      result << {
	        special_date_from: Date.parse(striped_item.first),
	        special_date_to: Date.parse(striped_item.last),
	        cultivate_working_days: (special_days - free_days).count
	      }

	      result
	    end
	  end

	  def strip_value(value)
	    value.gsub(/[0-9]*\.?[0-9]+[(|（]/, '').gsub(/[)|）]/, '')
	      .gsub(/\s/, '').split(/[,|，]/)
	      .map{|item| item.split(/[~|～]/)}
	  end

	  def valid?
	    @error.size == 0
	  end

	  def is_value_empty?(row)
	    headers.values.inject([]) do |result, index|
	      result << row[index] if row[index]
	      result
	    end.empty?
	  end

	  def valid_format_for(row)
	    name = "员工编号#{row[4]}"
	    headers.each do |key, index|
	      col_value = row[index].to_s

	      next unless col_value

	      col_value.gsub!(/\s+/, "")
	      col_values = col_value.split(/[,|，]/)
	      prediction = col_values.select do |value|
	        result = value.scan(/[0-9]*\.?[0-9]+[(|（]\d+.*[~|～]\d+.*[)|）]/)
	        result.empty? || result.flatten.first != value
	      end.empty?

	      unless prediction
	        @error << "#{name}: #{local_headers(key)}填写格式有误"
	        break
	      end
	    end

	    if @error.length == 0
        return true
      else
        return false
      end
	  end

	  def headers
	    {
	      "AnnualPrev_ADD" => 10,
	      "AnnualCurrent_ADD" => 11,
	      "marriage_funeral_leave_ADD" => 12,
	      "prenatal_check_leave_ADD" => 13,
	      "family_plan_leave_ADD" => 14,
	      "lactation_leave_ADD" => 15,
	      "women_leave_ADD" => 16,
	      "Flow::MaternityLeave" => 17,
	      "rear_nurse_leave_ADD" => 18,
	      "injury_leave_ADD" => 19,
	      "recuperate_leave_ADD" => 20,
	      "accredit_leave_ADD" => 21,
	      "Flow::SickLeave" => 22,
	      "Flow::SickLeaveInjury" => 23,
	      "Flow::SickLeaveNulliparous" => 24,
	      "Flow::PersonalLeave" => 26,
	      "Flow::HomeLeave" => 27,
	      "Flow::Cultivate" => 28,
	      "Flow::Evection" => 29,
	      "absenteeism_ADD" => 30,
	      "late_or_leave_ADD" => 31,
	      "Flow_flight_grounded" => 32,
	      "Flow_flight_grounded_work" => 33,
	      "Station_group_ADD" => 34
	    }
	  end

	  def local_headers(key)
	    {
	      "AnnualPrev_ADD" => "去年年假总计",
	      "AnnualCurrent_ADD" => "今年年假总计",
	      "marriage_funeral_leave_ADD" => "婚丧假",
	      "prenatal_check_leave_ADD" => "产前检查假",
	      "family_plan_leave_ADD" => "计生假",
	      "lactation_leave_ADD" => "哺乳假",
	      "women_leave_ADD" => "女工假",
	      "Flow::MaternityLeave" => "产假",
	      "rear_nurse_leave_ADD" => "生育护理假",
	      "injury_leave_ADD" => "工伤假",
	      "recuperate_leave_ADD" => "疗养假",
	      "accredit_leave_ADD" => "派驻休假",
	      "Flow::SickLeave" => "病假",
	      "Flow::SickLeaveInjury" => "病假（工伤待定）",
	      "Flow::SickLeaveNulliparous" => "病假（怀孕待产）",
	      "Flow::PersonalLeave" => "事假",
	      "Flow::HomeLeave" => "探亲假",
	      "Flow::Cultivate" => "培训",
	      "Flow::Evection" => "出差",
	      "absenteeism_ADD" => "矿工",
	      "late_or_leave_ADD" => "迟到早退",
	      "Flow_flight_grounded" => "空勤人员停飞",
	      "Flow_flight_grounded_work" => "空勤人员停飞并从事地面工作",
	      "Station_group_ADD" => "驻站天数"
	    }[key]
	  end
	end
end
