require 'spreadsheet'

module Excel
  class HoursFeeImporter

    def self.import_fly_fee(file_path, month)
      sheet = get_sheet(file_path)

      error_names, error_count = [], 0

      HoursFee.transaction do
        sheet.each_with_index do |row, index|
          next if index == 0 || %w(级别 制表 合计).include?(row[0])
          employee_no = row[2].respond_to?(:value) ? row[2].value : row[2]
          employee = Employee.find_by(employee_no: employee_no)
          if employee.blank?
            error_names << row[1]
            error_count += 1
          else
            hours_fee = employee.hours_fees.find_or_create_by(month: month, hours_fee_category: '飞行员')
            is_not_fly_sky = row[5].to_f == 0 && row[16].to_f > 0
            hours_fee.update(
              reality_fly_hours: row[3].to_f.round(5),
              fly_hours: row[4].to_f,
              total_hours_fee: row[22].to_f,
              total_security_fee: row[25].to_f,
              demo_fly_money: row[16].to_f,
              is_not_fly_sky: is_not_fly_sky
            )
          end
        end
      end

      {
        success_count: sheet.count - error_count - 1,
        error_count: error_count,
        error_names: error_names
      }
    end

    def self.import_service_fee(file_path, month)
      sheet = get_sheet(file_path)

      error_names, error_count = [], 0
      HoursFee.transaction do
        sheet.each_with_index do |row, index|
          next if index == 0 || %w(级别 制表 合计).include?(row[0])
          employee_no = row[2].respond_to?(:value) ? row[2].value : row[2]
          employee = Employee.find_by(employee_no: employee_no)
          if employee.blank?
            error_names << row[1]
            error_count += 1
          else
            hours_fee = HoursFee.find_or_create_by(employee_id: employee.id, month: month, hours_fee_category: '乘务员')
            hours_fee.update(
              reality_fly_hours: row[3].to_f.round(5),
              fly_hours: row[4].to_f,
              total_hours_fee: row[15].to_f
            )
          end
        end
      end

      {
        success_count: sheet.count - error_count - 1,
        error_count: error_count,
        error_names: error_names
      }
    end

    def self.import_security_fee(file_path, month)
      sheet = get_sheet(file_path)

      error_names, error_count = [], 0

      HoursFee.transaction do
        sheet.each_with_index do |row, index|
          next if index == 0 || %w(级别 制表 合计).include?(row[0])
          employee_no = row[2].respond_to?(:value) ? row[2].value : row[2]
          employee = Employee.find_by(employee_no: employee_no)
          if employee.blank?
            error_names << row[1]
            error_count += 1
          else
            hours_fee = HoursFee.find_or_create_by(employee_id: employee.id, month: month, hours_fee_category: '安全员')
            hours_fee.update(
              reality_fly_hours: row[3].to_f.round(5),
              fly_hours: row[4].to_f,
              total_hours_fee: row[16].to_f
            )
          end
        end
      end

      {
        success_count: sheet.count - error_count - 1,
        error_count: error_count,
        error_names: error_names
      }
    end

    def self.import_service_upper(file_path, month)
      sheet = get_sheet(file_path)

      error_names, error_count = [], 0

      HoursFee.transaction do
        sheet.each_with_index do |row, index|
          next if index == 0
          employee = Employee.find_by(employee_no: row[0], name: row[1])
          if employee.blank? || employee.hours_fees.where(month: month).blank?
            error_names << row[1]
            error_count += 1
          else
            employee.hours_fees.where(month: month).update_all(up_or_down: 'up')
          end
        end
      end

      {
        success_count: sheet.count - error_count - 1,
        error_count: error_count,
        error_names: error_names
      }
    end

    def self.import_service_lower(file_path, month)
      sheet = get_sheet(file_path)

      error_names, error_count = [], 0

      HoursFee.transaction do
        sheet.each_with_index do |row, index|
          next if index == 0
          employee = Employee.find_by(employee_no: row[0], name: row[1])
          if employee.blank? || employee.hours_fees.where(month: month).blank?
            error_names << row[1]
            error_count += 1
          else
            employee.hours_fees.where(month: month).update_all(up_or_down: 'down')
          end
        end
      end

      {
        success_count: sheet.count - error_count - 1,
        error_count: error_count,
        error_names: error_names
      }
    end

    def self.import_delicacy_reward(file_path, month)
      sheet = get_sheet(file_path)

      error_names, error_count = [], 0

      HoursFee.transaction do
        sheet.each_with_index do |row, index|
          next if index == 0
          employee_no = row[1].respond_to?(:value) ? row[1].value : row[1]
          employee = Employee.find_by(employee_no: employee_no)
          hours_fees = employee.hours_fees.where(month: month) if employee
          if employee.blank? || hours_fees.blank? || (hours_fees.map(&:hours_fee_category).exclude?("乘务员") && 
            hours_fees.map(&:hours_fee_category).exclude?("安全员"))
            error_names << row[1]
            error_count += 1
          else
            hours_fee = hours_fees.select{|h| h.hours_fee_category == "安全员"}.first || hours_fees.first
            hours_fee.update(delicacy_reward: row[3].to_f)
          end
        end
      end

      {
        success_count: sheet.count - error_count - 1,
        error_count: error_count,
        error_names: error_names
      }
    end

    def self.import_service_land_work(file_path, month)
      sheet = get_sheet(file_path)

      error_names, error_count = [], 0

      HoursFee.transaction do
        sheet.each_with_index do |row, index|
          next if index == 0
          employee = Employee.find_by(employee_no: row[0])
          if employee.blank? || employee.hours_fees.where(month: month).blank?
            error_names << row[1]
            error_count += 1
          else
            employee.hours_fees.where(month: month).update_all(is_land_work: true, land_work_money: row[2] || 1200)
          end
        end
      end

      {
        success_count: sheet.count - error_count - 1,
        error_count: error_count,
        error_names: error_names
      }
    end

    def self.import_add_garnishee(file_path, month, hours_fee_category)
      sheet = get_sheet(file_path)

      employees, error_names, error_count = {}, [], 0
      
      sheet.each_with_index do |row, index|
        next if index == 0
        employee = Employee.find_by(employee_no: row[0], name: row[1])
        if employee.blank?
          error_names << row[1]
          error_count += 1
        else
          employees.merge!({employee.employee_no => employee})
        end
      end

      if error_count > 0
        return {
          success_count: sheet.count - error_count - 1,
          error_count: error_count,
          error_names: error_names
        }
      end

      HoursFee.transaction do
        sheet.each_with_index do |row, index|
          next if index == 0
          employee = employees[row[0]]
          hours_fee = employee.hours_fees.find_or_create_by(month: month, hours_fee_category: hours_fee_category)

          hours_fee.assign_attributes(add_garnishee: row[2], remark: hours_fee.remark.to_s + row[3])

          channel = CodeTable::Channel.find_by(id: hours_fee.channel_id).try(:display_name)

          is_deduce = 0
          hours_fees = HoursFee.where(employee_id: hours_fee.employee_id, month: month)
          if channel == '空勤' && hours_fee.add_garnishee_changed? && (hours_fees.size == 1 || 
            hours_fee.hours_fee_category == '安全员') && hours_fee.fly_fee
            is_deduce = 1
            if hours_fee.airline_fee.to_f > 0
              if hours_fee.fly_fee.to_f + hours_fee.add_garnishee.to_f >= 0 && hours_fee.employee.salary_person_setup.is_send_airline_fee
                is_deduce = 2
              else
                hours_fee.fly_fee += hours_fee.airline_fee
                hours_fee.total = hours_fee.fly_fee + hours_fee.fertility_allowance.to_f
                hours_fee.airline_fee = 0
              end
            else
              fly_hours = hours_fees.map(&:fly_hours).map(&:to_f).inject(:+).to_f
              if %w(领导 干部).include?(hours_fee.employee.category.try(:display_name))
                hours_fee.airline_fee = 912.5 if fly_hours > 0
              else
                hours_fee.airline_fee = fly_hours*10 > 912.5 ? 912.5 : fly_hours*10
              end

              if fly_hours > 0 && hours_fee.fly_fee.to_f + hours_fee.add_garnishee.to_f >= hours_fee.airline_fee && hours_fee.employee.salary_person_setup.is_send_airline_fee
                hours_fee.fly_fee -= hours_fee.airline_fee
                hours_fee.total = hours_fee.fly_fee + hours_fee.fertility_allowance.to_f
                is_deduce = 2
              end
            end
          end

          if hours_fee.save
            calc_steps = CalcStep.where(employee_id: hours_fee.employee_id, month: month).where(
              "category='hours_fee/security' or category='hours_fee/service'")
            calc_step = calc_steps.first
            if is_deduce == 2
              calc_steps.update_all(step_notes: calc_step.push_step("#{calc_step.step_notes.size + 1}. " + 
                "导入补扣发为: #{hours_fee.add_garnishee}, 需在小时费中扣除空勤灶"), amount: hours_fee.total)
            elsif is_deduce == 1
              calc_steps.update_all(step_notes: calc_step.push_step("#{calc_step.step_notes.size + 1}. " + 
                "导入补扣发为: #{hours_fee.add_garnishee}, 因薪酬个人设置不发放空勤灶、小时费不足或本月无飞行时间不扣除空勤灶, 无空勤灶"), amount: hours_fee.total)
            end
          end

        end
      end

      {
        success_count: sheet.count - error_count - 1,
        error_count: error_count,
        error_names: error_names
      }
    end

    def self.import_refund_fee(file_path, month, hours_fee_category)
      sheet = get_sheet(file_path)

      employees, error_names, error_count = {}, [], 0

      HoursFee.transaction do
        sheet.each_with_index do |row, index|
          next if index == 0
          employee = Employee.find_by(employee_no: row[1], name: row[0])

          if employee.blank?
            error_names << row[0]
            error_count += 1
          else
            hours_fee = employee.hours_fees.find_by(month: month, hours_fee_category: hours_fee_category)
            hours_fee = employee.hours_fees.create(month: month, hours_fee_category: hours_fee_category) if hours_fee.blank?

            hours_fee.update(refund_fee: row[2])
          end
        end
      end

      {
        success_count: sheet.count - error_count - 1,
        error_count: error_count,
        error_names: error_names
      }
    end

    private
    def self.compute_time(time)
      hour_miu = time.try(:split, ':')
      return 0 if hour_miu.blank?
      hour_miu[0].to_i + (hour_miu[1].to_i/60.0).round(2)
    end

    def self.get_sheet(file_path)
      book = Spreadsheet.open("#{Rails.root}/public/#{file_path}")
      book.worksheet 0
    end

  end
end
