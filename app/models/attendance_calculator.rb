# AttendanceCalculator
# 1. 计算请假的天数计算
# 2. 计算考勤的天数计算

class AttendanceCalculator
  class << self
    def change_leave_days(condition, employee, attendance_summary = nil, skip_check = false, deduct = false)
      attendance_summary = attendance_summary || get_attendance_summary(employee)

      if skip_check || attendance_summary.can_summary?
        $redis.lock("attendance_summary:#{attendance_summary.id}") do
          attendance_summary.reload
          ex_name = get_leave_name(condition[:ex_type])
          name = get_leave_name(condition[:type])

          reduce_days(
            ex_name,
            condition[:ex_vacation_days],
            attendance_summary
          )

          add_days(
            name,
            condition[:vacation_days],
            attendance_summary
          )

          reduce_days(
            "paid_leave",
            condition[:ex_vacation_days],
            attendance_summary
          ) if paid_types.include?(condition[:ex_type])

          add_days(
            "paid_leave",
            condition[:vacation_days],
            attendance_summary
          ) if paid_types.include?(condition[:type])

          if deduct
            reduce_days(
              work_date_types[condition[:ex_type]],
              deduct_work_days(condition[:start_time], condition[:end_time], condition[:ex_vacation_days]),
              attendance_summary
            ) if work_date_types.keys.include?(condition[:ex_type])
          else
            reduce_days(
              work_date_types[condition[:ex_type]],
              work_days(condition[:start_time], condition[:end_time], condition[:ex_vacation_days]),
              attendance_summary
            ) if work_date_types.keys.include?(condition[:ex_type])
          end

          add_days(
            work_date_types[condition[:type]],
            work_days(condition[:start_time], condition[:end_time], condition[:vacation_days]),
            attendance_summary
          ) if work_date_types.keys.include?(condition[:type])

        end
      end
    end

    def add_leave_days(condition, employee, attendance_summary = nil)
      attendance_summary = attendance_summary || get_attendance_summary(employee)
      $redis.lock("attendance_summary:#{attendance_summary.id}") do
        attendance_summary.reload
        name = get_leave_name(condition[:type])

        add_days(
          name,
          condition[:vacation_days],
          attendance_summary
        )

        add_days(
          "paid_leave",
          condition[:vacation_days],
          attendance_summary
        ) if paid_types.include?(condition[:type])

        add_days(
          work_date_types[condition[:type]],
          work_days(condition[:start_time], condition[:end_time], condition[:vacation_days]),
          attendance_summary
        ) if work_date_types.keys.include?(condition[:type])
      end
    end

    def reduce_leave_days(type, vacation_days, employee)
      attendance_summary = attendance_summary || get_attendance_summary(employee)

      if attendance_summary.can_summary?
        $redis.lock("attendance_summary:#{attendance_summary.id}") do
          attendance_summary.reload
          name = get_leave_name(type)

          reduce_days(name, vacation_days, attendance_summary)
          reduce_days("paid_leave", vacation_days, attendance_summary) if paid_types.include?(type)
        end
      end
    end

    def change_attendance_days(ex_type, type, employee, record_date)
      attendance_summary = get_attendance_summary(employee, record_date.strftime("%Y-%m"))

      $redis.lock("attendance_summary:#{attendance_summary.id}") do
        attendance_summary.reload
        ex_name = get_attendance_name(ex_type)
        name = get_attendance_name(type)

        reduce_days(ex_name, 1, attendance_summary)
        add_days(name, 1, attendance_summary)
      end
    end

    def add_attendance_days(type, employee, record_date)
      attendance_summary = get_attendance_summary(employee, record_date.strftime("%Y-%m"))

      $redis.lock("attendance_summary:#{attendance_summary.id}") do
        attendance_summary.reload
        name = get_attendance_name(type)

        add_days(name, 1, attendance_summary)
      end
    end

    def reduce_attendance_days(type, employee, record_date)
      attendance_summary = get_attendance_summary(employee, record_date.strftime("%Y-%m"))

      $redis.lock("attendance_summary:#{attendance_summary.id}") do
        attendance_summary.reload
        name = get_attendance_name(type)

        reduce_days(name, 1, attendance_summary)
      end
    end

    private
    def get_attendance_summary(employee, summary_date = Date.today.strftime("%Y-%m"))
      employee.attendance_summaries.find_by(summary_date: summary_date)
    end

    def add_days(name, days, attendance_summary)
      names = [name].flatten

      names.each do |method_name|
        attendance_summary.send("#{method_name}=", eval(attendance_summary.send(method_name)) + days)
      end

      attendance_summary.save!
    end

    def reduce_days(name, days, attendance_summary)
      names = [name].flatten

      names.each do |method_name|
        attendance_summary.send("#{method_name}=", eval(attendance_summary.send(method_name)) - days)
      end

      attendance_summary.save!
    end

    def work_days(start_time, end_time, vacation_days)
      start_date, end_date = start_time.to_date, end_time.to_date
      original_days = Range.new(start_date, end_date).to_a
      free_days = VacationRecord.check_free_days(start_date, end_date)
      if free_days.include?(start_date) || free_days.include?(end_date)
        temp_days = 0
        (temp_days += 0.5; original_days.delete(start_date)) if (free_days.include?(start_date) && start_time.include?("T#{Setting.daily_working_hours.afternoon}"))
        (temp_days += 0.5; original_days.delete(end_date)) if (free_days.include?(end_date) && end_time.include?("T#{Setting.daily_working_hours.afternoon}"))
        days = vacation_days - temp_days - (free_days & original_days).count
      else
        days = vacation_days - (free_days & original_days).count
      end

      return days
    end

    def deduct_work_days(start_time, end_time, vacation_days)
      # 假期抵扣的时候计算leave_work_day
      start_date, end_date = start_time.to_date, end_time.to_date
      original_days = Range.new(start_date, end_date).to_a
      free_days = VacationRecord.check_free_days(start_date, end_date)

      temp_days = 0

      if free_days.include?(start_date) || free_days.include?(end_date)
        (temp_days += 0.5; original_days.delete(start_date))  if (free_days.include?(start_date) && start_time.include?("T#{Setting.daily_working_hours.afternoon}"))
        (temp_days += 0.5; original_days.delete(end_date)) if (free_days.include?(end_date) && end_time.include?("T#{Setting.daily_working_hours.afternoon}"))
      end

      work_days = (original_days - free_days).size - temp_days
      [work_days, vacation_days].min
    end

    def paid_types
      %w(
       Flow::FuneralLeave Flow::MarriageLeave Flow::PrenatalCheckLeave
       Flow::WomenLeave Flow::RearNurseLeave Flow::MaternityLeave
       Flow::AccreditLeave Flow::LactationLeave Flow::MaternityLeaveBreastFeeding
       Flow::MaternityLeaveDystocia Flow::MaternityLeaveLateBirth Flow::MaternityLeaveMultipleBirth
       Flow::MiscarriageLeave Flow::OccupationInjury Flow::PublicLeave Flow::AnnualLeave Flow::OffsetLeave
      )
    end

    # 需要记录工作日天数的假期
    def work_date_types
      {
        "Flow::PersonalLeave"        => "personal_leave_work_days",
        "Flow::SickLeave"            => "sick_leave_work_days",
        "Flow::SickLeaveInjury"      => "sick_leave_work_days",
        "Flow::SickLeaveNulliparous" => "sick_leave_work_days",
        "Flow::HomeLeave"            => "home_leave_work_days"
      }
    end

    def get_leave_name(type)
      {
        "Flow::AccreditLeave"  => "accredit_leave", # 派驻人员休假
        "Flow::AnnualLeave"    => "annual_leave", # 年假
        "Flow::FuneralLeave"   => "marriage_funeral_leave", # 丧假
        "Flow::HomeLeave"      => "home_leave", # 探亲假
        "Flow::MarriageLeave"  => "marriage_funeral_leave", # 婚假
        "Flow::MaternityLeave" => "maternity_leave", # 产假
        "Flow::MaternityLeaveBreastFeeding" => "maternity_leave", # 产假(母乳喂养)
        "Flow::MaternityLeaveDystocia"      => "maternity_leave", # 产假(剖腹产、难产)
        "Flow::MaternityLeaveLateBirth"     => "maternity_leave", # 产假(晚育)
        "Flow::MaternityLeaveMultipleBirth" => "maternity_leave", # 产假(多胞胎)
        "Flow::MiscarriageLeave"     => ["maternity_leave", "miscarriage_leave"], # 产假(流产)
        "Flow::PersonalLeave"        => "personal_leave", # 事假
        "Flow::PrenatalCheckLeave"   => "prenatal_check_leave", # 产前孕期检查假
        "Flow::RearNurseLeave"       => "rear_nurse_leave", # 生育护理假
        "Flow::SickLeave"            => "sick_leave", # 病假
        "Flow::SickLeaveInjury"      => "sick_leave_injury", # 病假(工伤待定)
        "Flow::SickLeaveNulliparous" => "sick_leave_nulliparous", # 病假(怀孕待产)
        "Flow::WomenLeave"       => "women_leave", # 女工假
        "Flow::LactationLeave"   => "lactation_leave", # 哺乳假
        "Flow::OccupationInjury" => "injury_leave", # 工伤假
        "Flow::PublicLeave"      => "public_leave", # 公假
        "Flow::OffsetLeave"      => 'offset_leave', # 补休假
        "Flow::RecuperateLeave"  => "recuperate_leave", # 疗养假
        "cultivate"              => "cultivate", # 离岗培训
      }[type]
    end

    def get_attendance_name(type)
      return "late_or_leave" if %w(迟到 早退).include?(type)
      return "absenteeism"
    end
  end
end
