class NightFee < ActiveRecord::Base
  belongs_to :employee

  validates :month, uniqueness: { scope: [:month, :employee_id] }

  COLUMNS = %w(no employee_id month employee_no employee_name shifts_type location night_number notes subsidy amount flag is_invalid)

  EXPORTOR_TYPE = {
    "夜餐费审批表" => :export_approve_table,
    "机关食堂夜班费充值表" => :export_office_charge_table,
    "机关食堂夜班费充值表" => :export_north_part_charge_table
  }

  def check_invalid
    (self.shifts_type == "两班倒" && self.night_number > 16) || (self.shifts_type == "三班倒" && self.night_number > 11) || (self.shifts_type == "四班倒" && self.night_number > 8)
  end

  def self.compute(month)
    CalcStep.remove_items('dinner_fee', month)
    NightFee.where(month: month).delete_all

    t1 = Time.new

    NightFee.transaction do
      @values = []
      @calc_values = []

      @employee_hash = Employee.all.index_by(&:name)

      NightRecord.where(month: month).each do |nr|
        employee = @employee_hash[nr.employee_name]
        next unless employee

        hash = {employee_id: employee.id, category: 'night_fee', month: month}
        calc_step = CalcStep.find_or_initialize_by(hash)
        calc_step.push_step("夜餐次数 #{nr.night_number}, 标准: #{nr.subsidy}")
        @amount = nr.calc_amount()
        calc_step.final_amount(@amount)

        @values << [nr.no, employee.id, month, nr.employee_no, nr.employee_name, nr.shifts_type, nr.location, nr.night_number, nr.notes, nr.subsidy, @amount, nr.flag, nr.is_invalid]
        @calc_values << [calc_step.employee_id, calc_step.month, calc_step.category, calc_step.step_notes, calc_step.amount]
      end
    end

    CalcStep.import(CalcStep::COLUMNS, @calc_values, validate: false)
    NightFee.import(COLUMNS, @values, validate: false)
    @calc_values.clear
    @values.clear

    t2 = Time.new
    puts "计算耗费 #{t2 - t1} 秒"

    return true
  end
end
