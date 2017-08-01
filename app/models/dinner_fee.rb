class DinnerFee < ActiveRecord::Base
  belongs_to :employee

  validates :month, uniqueness: { scope: [:month, :employee_id] }

  COLUMNS = %w(employee_id month employee_no employee_name shifts_type area card_amount card_number working_fee backup_fee)

  IMPORTOR_TYPE = {
    "空勤备份餐表" => :import_airline_backup,
    "空保备份餐标" => :import_air_security_backup,
    "长水机场值班数据" => :import_cs_airport_workovertime
  }

  EXPORTOR_TYPE = {
    "机关食堂拨付表" => :export_office_charge_table,
    "北头食堂拨付表" => :export_north_part_charge_table,
    "重庆食堂拨付表" => :export_cq_payment_table,
    "重宾食堂拨付表" => :export_cb_payment_table,
    "昆明食堂拨付表" => :export_km_payment_table,
    "长水机场值班发放表" => :export_cs_airport_cash_send_table,
    "其他现金区域发放表" => :export_others_cash_send_table,
    "空勤灶充值表" => :export_airline_charge_table,
    "空勤灶发放表" => :export_airline_send_table,
    "备份餐充值表" => :export_backup_charge_table,
    "重庆食堂备份餐发放表" => :export_cq_backup_send_table,
    "昆明食堂备份餐发放表" => :export_km_backup_send_table,
    "备份打印表" => :export_backup_print_table

  }

  def uniq_key
    self.area + self.employee_no
  end

  def self.compute(month, type)
    # 在数据表里面 9 月份的工作餐和 9 月份的误餐费/备份餐是同一条记录
    # 在算 9 月份的饭卡数据的时候，就预先建立了 9 月份的误餐费/备份餐记录，金额都为0，等着被更新

    # 界面默认显示当月月份，由操作者选择要发放的月份，这个前提很重要!!!
    if type == "工作餐"
      # 8 月底算 9 月 的饭卡，界面选择 9 月，只有 7 月的考勤出来了，所以是看 7 月的考勤
      look_month = Date.parse(month + "-01").prev_month.prev_month.strftime("%Y-%m")

      # 计算工作餐的时候把当月的记录删除
      DinnerFee.where(month: month).delete_all
    elsif type == "误餐费"
      # 10 月算 9 月的误餐费，9 月的考勤出来了的，所以是看 9 的考勤
      look_month = month
      @df_hash = {}

      DinnerRecord.where(month: month).find_in_batches do |group|
        group.each {|record|@df_hash[record.uniq_key] = record}
      end

      DinnerFee.where(month: month).delete_all
    end

    # TODO 暂停发放->暂停恢复后考勤看的是暂停发放对应的变动日期对应月份的考勤
    # 暂停发放变动的当月是全月发放，正发，恢复后再来扣除

    is_success, messages = AttendanceSummary.can_calc_salary?(look_month)
    return [is_success, messages] unless is_success

    CalcStep.remove_items('dinner_fee', month)

    t1 = Time.new

    DinnerPersonSetup.transaction do
      @values = []
      @calc_values = []

      if type == "工作餐"
        @setups = DinnerPersonSetup.where("is_suspend = 0 AND card_number > 0")
      elsif type == "误餐费"
        @setups = DinnerPersonSetup.where("is_suspend = 0 AND card_number = 0")
      end

      @setups.joins("LEFT JOIN employees ON employees.id=dinner_person_setups.employee_id").each do |dps|
        employee = dps.employee
        hash = {employee_id: employee.id, category: 'dinner_fee', month: month}
        calc_step = CalcStep.find_or_initialize_by(hash)

        # 先修复是否全月满算!!!
        # 新进、变动、修改班制等都会造成计算数值基础改变!!!
        dps.check_and_fix_setting(month, type)

        # 休假、离岗、出差、驻站
        dps.process_normal(month, calc_step, 'vacation', type)
        dps.process_normal(month, calc_step, 'leave_position', type)
        dps.process_normal(month, calc_step, 'business_trip', type)
        dps.process_landing(month, calc_step, type)

        if type == "工作餐"
          @values << [dps.employee_id, month, dps.employee_no, dps.employee_name, dps.shifts_type, dps.area, dps.card_amount, dps.card_number, 0, 0]
        elsif type == "误餐费"
          @values << [dps.employee_id, month, dps.employee_no, dps.employee_name, dps.shifts_type, dps.area, @df_hash[dps.uniq_key].card_amount, @df_hash[dps.uniq_key].card_number, dps.working_fee, 0]
        end

        @calc_values << [calc_step.employee_id, calc_step.month, calc_step.category, calc_step.step_notes, calc_step.amount]
      end

      CalcStep.import(CalcStep::COLUMNS, @calc_values, validate: false)
      DinnerFee.import(COLUMNS, @values, validate: false)
      @calc_values.clear
      @values.clear
    end

    t2 = Time.new
    puts "计算耗费 #{t2 - t1} 秒"

    return true
  end
end
