require "spreadsheet"

module Excel
  class AttendanceSummaryWriter
    attr_reader :filename, :path

    def initialize(data)
      @data = data
      @filename = CGI::escape("#{Time.now.to_i}考勤汇总表.xls")
      @path = "#{Rails.root}/public/export/tmp/#{@filename}"
      @workbook = Spreadsheet.open("#{Rails.root}/public/attendance_summary/attendance_summary_template.xls")
      @sheet = @workbook.worksheet(0)
      @row = 1
    end

    def headers
      %w(
      employee_no employee_name labor_relation start_work_date join_scal_date channel annual_leave_2015 annual_leave_2016 marriage_funeral_leave
      prenatal_check_leave family_planning_leave lactation_leave women_leave
      maternity_leave rear_nurse_leave injury_leave recuperate_leave accredit_leave
      sick_leave sick_leave_injury sick_leave_nulliparous sick_leave_total sick_leave_work_days
      personal_leave personal_leave_work_days home_leave home_leave_work_days cultivate cultivate_work_days
      evection evection_work_days absenteeism late_or_leave ground ground_work_days surface_work station_days station_place remark
      )
    end

    def write_excel
      @data.find_each do |attendance_summary|
        write_attendance_summary(attendance_summary)
        @row += 1
      end

      write_workbook
      self
    end

    def write_attendance_summary(attendance_summary)
      row_values = get_values_for(attendance_summary)

      @sheet.row(@row).push(*row_values)
    end

    def get_values_for(attendance_summary)
      department_values(attendance_summary) + summary_values(attendance_summary)
    end

    def summary_values(attendance_summary)
      prev_year = Time.now.prev_year.year.to_s
      now_year = Time.now.year.to_s
      headers.inject([]) do |result, method_name|
        employee = Employee.find_by(id:attendance_summary.employee_id)
        if method_name == 'sick_leave_total' #病假总计
          result << attendance_summary.send('sick_leave').to_f + attendance_summary.send('sick_leave_injury').to_f + attendance_summary.send('sick_leave_nulliparous').to_f
        elsif method_name == 'start_work_date'
          result << employee.try(:start_work_date).to_s
        elsif method_name == 'join_scal_date'
          result << employee.try(:join_scal_date).to_s
        elsif method_name == 'channel'
          result << employee.try(:channel).try(:display_name)
        elsif method_name == 'annual_leave_2015'
          result << (attendance_summary.summary_date.split('-').first == prev_year ? attendance_summary.annual_leave : '0')
        elsif method_name == 'annual_leave_2016'
          result << (attendance_summary.summary_date.split('-').first == now_year ? attendance_summary.annual_leave : '0')
        else
          result << attendance_summary.send(method_name)
        end
        result
      end
    end

    def department_values(attendance_summary)
      dep_chain = Department.find(attendance_summary.department_id).parent_chain

      %w(branch_company positive deputy secondly_positive).inject([]) do |dep_values, grade_name|
        dep = dep_chain.detect{|dep| dep.grade.name == grade_name}
        dep_values << dep.try(:name)
        dep_values
      end
    end

    def write_workbook
      @workbook.write(@path)
    end
  end
end
