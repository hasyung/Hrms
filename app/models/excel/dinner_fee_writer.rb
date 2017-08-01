module Excel
  class DinnerFeeWriter
    # TODO 导出的充值表需要过滤暂停发放的个人设置

    def self.office_charge_table(month, file_path)
      office_north_part("机关明细", month, file_path)
    end

    def self.north_part_charge_table
      office_north_part("北头明细", month, file_path)
    end

    def self.cq_payment_table
      #
    end

    def self.cb_payment_table
      #
    end

    def self.km_payment_table
      #
    end

    def self.cs_airport_cash_send_table
      #
    end

    def self.others_cash_send_table
      #
    end

    def self.airline_charge_table
      #
    end

    def self.airline_send_table
      #
    end

    def self.backup_charge_table
      #
    end

    def self.cq_backup_send_table
      #
    end

    def self.km_backup_send_table
      #
    end

    def self.backup_print_table
      #
    end

    private

    def self.office_north_part(category, month, file_path)
      t1 = Time.new

      @data_month = Date.parse(month + "-01").prev_month.strftime("%Y-%m")
      @data = DinnerRecord.where(category: category, month: @data_month, record_type: ["联网售饭", "固定扣款", "独立售饭", "退票"]).order("employee_no")
      @book = Spreadsheet::Workbook.new

      @sheet = @book.create_worksheet(name: "#{@data_month}消费流水")

      ["帐号", "姓名", "帐务日期", "实际时间", "时段", "帐务类型", "计算机号", "POS机号", "交易金额", "库中余额", "操作员"].each_with_index do |name, column|
        @sheet[0, column] = name
      end

      @current_row = 0

      @data.each_with_index do |dr, row|
        @current_row = row + 1

        @sheet[@current_row, 0] = dr.employee_no
        @sheet[@current_row, 1] = dr.employee_name
        @sheet[@current_row, 2] = dr.record_date.strftime("%Y-%m-%d %H:%M:%S")
        @sheet[@current_row, 3] = dr.real_time
        @sheet[@current_row, 4] = dr.time_range
        @sheet[@current_row, 5] = dr.record_type
        @sheet[@current_row, 6] = dr.computer_no
        @sheet[@current_row, 7] = dr.pos_no
        @sheet[@current_row, 8] = dr.amount
        @sheet[@current_row, 9] = dr.store_balance
        @sheet[@current_row, 10] = dr.operator
      end

      @sheet = @book.create_worksheet(name: "消费")

      ["帐号", "姓名", "帐务日期", "实际时间", "时段", "帐务类型", "计算机号", "POS机号", "交易金额", "补贴金额", "合计"].each_with_index do |name, column|
        @sheet[0, column] = name
      end

      @current_row = 0
      @amount_sum = @subsidy_sum = @total = 0

      @data.each_with_index do |dr, row|
        if @last_no.present? && dr.employee_no != @last_no
          @current_row = @current_row + 1
          bold = Spreadsheet::Format.new :weight => :bold
          @sheet.row(@current_row).set_format(0, bold)
          @sheet[@current_row, 0] = dr.employee_no
          @sheet[@current_row, 8] = @amount_sum
          @sheet[@current_row, 9] = @subsidy_sum
          @sheet[@current_row, 10] = @total
          @amount_sum = @subsidy_sum = @total = 0
        end

        @current_row = @current_row + 1

        @sheet[@current_row, 0] = dr.employee_no
        @sheet[@current_row, 1] = dr.employee_name
        @sheet[@current_row, 2] = dr.record_date.strftime("%Y-%m-%d %H:%M:%S")
        @sheet[@current_row, 3] = dr.real_time
        @sheet[@current_row, 4] = dr.time_range
        @sheet[@current_row, 5] = dr.record_type
        @sheet[@current_row, 6] = dr.computer_no
        @sheet[@current_row, 7] = dr.pos_no
        @sheet[@current_row, 8] = dr.amount
        @sheet[@current_row, 9] = dr.subsidy_amount
        @sheet[@current_row, 10] = dr.amount + dr.subsidy_amount

        @last_no = dr.employee_no
        @amount_sum += dr.amount
        @subsidy_sum += dr.subsidy_amount
        @total += (dr.amount + dr.subsidy_amount)
      end

      @data = DinnerRecord.where(category: category, month: @data_month, record_type: ["日发补助", "联网售票"]).order("employee_no")
      @sheet = @book.create_worksheet(name: "充值")

      ["帐号", "姓名", "帐务日期", "实际时间", "时段", "帐务类型", "计算机号", "POS机号", "交易金额"].each_with_index do |name, column|
        @sheet[0, column] = name
      end

      @total = 0
      @current_row = 0

      @data.each_with_index do |dr, row|
        if @last_no.present? && dr.employee_no != @last_no
          @current_row = @current_row + 1
          bold = Spreadsheet::Format.new :weight => :bold
          @sheet.row(@current_row).set_format(0, bold)
          @sheet[@current_row, 0] = dr.employee_no
          @sheet[@current_row, 8] = @total
          @total = 0
        end

        @current_row = @current_row + 1

        @sheet[@current_row, 0] = dr.employee_no
        @sheet[@current_row, 1] = dr.employee_name
        @sheet[@current_row, 2] = dr.record_date.strftime("%Y-%m-%d %H:%M:%S")
        @sheet[@current_row, 3] = dr.real_time
        @sheet[@current_row, 4] = dr.time_range
        @sheet[@current_row, 5] = dr.record_type
        @sheet[@current_row, 6] = dr.computer_no
        @sheet[@current_row, 7] = dr.pos_no
        @sheet[@current_row, 8] = dr.amount

        @last_no = dr.employee_no
        @total += dr.amount
      end

      @sheet = @book.create_worksheet(name: "传媒")

      ["员工代码", "餐卡卡号", "姓名", "消费", "充值", "实际金额"].each_with_index do |name, column|
        @sheet[0, column] = name
      end

      @names = Employee.joins("LEFT JOIN departments ON departments.id = employees.department_id").where("departments.full_name LIKE '文化传媒%'").map(&:name)
      @data = DinnerRecord.where(category: "机关明细", month: @data_month, employee_name: @names).order("employee_no")

      @current_row = 0
      @consume = @charge = @total = 0

      @data.each_with_index do |dr, row|
        if @last_no.present? && dr.employee_no != @last_no
          @current_row = @current_row +1
          @sheet[@current_row, 0] = dr.employee_no.downcase.gsub("w", "").gsub("g", "")
          @sheet[@current_row, 1] = dr.employee_no
          @sheet[@current_row, 2] = dr.employee_name
          @sheet[@current_row, 3] = @consume
          @sheet[@current_row, 4] = @charge
          @sheet[@current_row, 5] = (@consume - @charge)

          @total = @total + (@consume - @charge)
          @consume = @charge = 0
        end

        @last_no = dr.employee_no

        if ["联网售饭", "固定扣款", "独立售饭", "退票"].include?(dr.record_type)
          @consume += dr.amount
        end

        if ["日发补助", "联网售票"].include?(dr.record_type)
          @charge += dr.amount
        end
      end

      @sheet[@current_row + 1, 5] = @total

      @sheet = @book.create_worksheet(name: "补发")
      @sheet = @book.create_worksheet(name: "计算表")
      @sheet = @book.create_worksheet(name: "拨付表")

      @sheet[0, 0] = "项目"
      @sheet[0, 1] = "金额"
      @sheet[0, 2] = "备注"
      @sheet[1, 0] = "机关食堂总结"
      @sheet[2, 0] = "空勤食堂总计"
      @sheet[3, 0] = "拨付总额"

      @book.write file_path

      t2 = Time.new
      puts "计算耗费 #{t2 - t1} 秒"
    end
  end
end