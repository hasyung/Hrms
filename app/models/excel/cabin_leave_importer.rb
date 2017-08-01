require "spreadsheet"

module Excel
  class CabinLeaveImporter
    attr_reader :errors, :datas, :operator
    def initialize(file, operator, month)
      @sheet = Spreadsheet.open(file).worksheet(0)
      @operator = operator
      @errors = []
      @datas = []
      @month = month
    end

    def read_excel
      @sheet.each_with_index do |row, index|
        next if index == 0
        next if row_valid?(row)
        next if !cell_presence_valid?(row, index)

        employee = Employee.find_by(name: row[1], employee_no: row[2])
        if employee.nil?
          @errors << "#{index + 1}行：人员#{row[1]}未找到"
          next
        end
        next if !flow_valid?(employee, row, index)

        leave_range_date = row[3].gsub(/[0-9]*\.?[0-9]+[(|（]/, '').gsub(/[)|）]/, '').split("~")
        start_time = (leave_range_date.first =~ /下午/) ? leave_range_date.first.sub(/下午/, "T#{Setting.daily_working_hours.afternoon}+08:00") : "#{leave_range_date.first}T#{Setting.daily_working_hours.morning}+08:00"
        end_time = (leave_range_date.last =~ /上午/) ? leave_range_date.last.sub(/上午/, "T#{Setting.daily_working_hours.afternoon}+08:00") : "#{leave_range_date.last}T#{Setting.daily_working_hours.afternoon_end}+08:00"
        day = VacationRecord.cals_days(
          employee_id: employee.id,
          start_time: start_time,
          end_time: end_time,
          start_date: start_time.to_date,
          end_date: end_time.to_date,
          vacation_type: row[4],
          is_contain_free_day: false
        )[:vacation_days]
        @datas << {
          sponsor_id:@operator.id,
          employee_name:row[1],
          employee_no:row[2],
          employee_id:employee.id,
          start_leave_date:start_time,
          end_leave_date:end_time,
          leave_type:row[4],
          vacation_dates:row[3].gsub(/[0-9]*\.?[0-9]+[(|（]/, '').gsub(/[)|）]/, ''),
          vacation_days:day,
          is_checking:0,
          import_month:@month
        }
      end

      self
    end

    def import
      prediction = true
      index = 1

      CabinVacationImport.transaction do
        @datas.each do |date|
          begin
            CabinVacationImport.create!(date)
            index += 1
          rescue Exception => e
            prediction = false
            errors << "第#{index}行，人员#{date.employee_name}导入失败！"
            raise e
          end
        end
      end

      return prediction
    end

    def flow_valid?(employee, data, index)
      unless %w(年假 疗养假).include?(data[4])
        errors << "#{index + 1}: 假别填写有误(只能填写年假和疗养假)"
        return false
      end

      leave_range_date = data[3].gsub(/[0-9]*\.?[0-9]+[(|（]/, '').gsub(/[)|）]/, '').split("~")
      begin
        leave_range_date.map{|leave_date| leave_date.to_date}
      rescue Exception => e
        errors << "#{index + 1}: 请假时间的日期格式填写有误"
        return false
      end
      start_date = (leave_range_date.first =~ /下午/) ? leave_range_date.first.sub(/下午/, "T#{Setting.daily_working_hours.afternoon}+08:00") : "#{leave_range_date.first}T#{Setting.daily_working_hours.morning}+08:00"
      end_date = (leave_range_date.last =~ /上午/) ? leave_range_date.last.sub(/上午/, "T#{Setting.daily_working_hours.afternoon}+08:00") : "#{leave_range_date.last}T#{Setting.daily_working_hours.afternoon_end}+08:00"
      day = VacationRecord.cals_days(
        employee_id: employee.id,
        start_time: start_date,
        end_time: end_date,
        start_date: start_date.to_date,
        end_date: end_date.to_date,
        vacation_type: data[4],
        is_contain_free_day: false
      )
      vacation_days = day[:vacation_days]

      puts "======================"
      puts "start_date: #{leave_range_date.first}"
      puts "end_date:   #{leave_range_date.last}"
      puts "vacation_days: #{vacation_days}"
        
      if data[3].partition("（").first.to_f != (data[4] == "年假" ? day[:total_days] : day[:working_days])
        errors << "#{index + 1}行：请假时间计算的天数和填写天数不一致"
        return false
      end

      return true
    end

    def cell_presence_valid?(data, index)
      prediction = true
      error = (1..4).inject("#{index + 1}行：") do |result, cell_index|
        unless data[cell_index]
          result += "#{cell_title(cell_index)}不能为空; "
          prediction = false
        end

        result
      end

      if prediction
        return true
      else
        errors << error
        return false
      end
    end


    def row_valid?(data)
      if data[3].nil? && data[4].nil?
        return true
      end
      return false
    end

    def cell_title(index)
      %w(所属科室 姓名 工号 请假时间 天数 具体明细)[index]
    end

    def flow_type(type)
      {"年假" => "Flow::AnnualLeave", "疗养假" => "Flow::RecuperateLeave"}[type]
    end

    
  end
end
