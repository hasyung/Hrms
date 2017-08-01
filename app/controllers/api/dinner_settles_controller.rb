class Api::DinnerSettlesController < ApplicationController
  def index
    if params[:month]
      @dinner_settles = DinnerSettle.joins("LEFT JOIN employees ON employees.id=dinner_settles.employee_id").joins("LEFT JOIN departments ON departments.id=employees.department_id").joins("LEFT JOIN employee_positions ON employee_positions.employee_id=employees.id WHERE employee_positions.category='主职' AND dinner_settles.month = '#{params[:month]}'")

      page = parse_query_params!("dinner_settle").values.last
      @dinner_settles = set_page_meta(@dinner_settles, page)

      render template: 'api/dinner_settles/index'
    else
      render json: {messages: "计算月份是必须的参数"}, status: 400
    end
  end

  def import
    attachment = Attachment.find_by(id: params[:attachment_id])

    if %w(xls xlsx).exclude?(attachment.file_type.downcase)
      return render json: {messages: "对不起，目前仅支持xls和xlsx文件导入"}, status: 400
    end

    if attachment.blank? || params[:month].blank? || params[:type].blank? || DinnerSettle::IMPORTOR_TYPE[params[:type]].blank?
      return render json: {messages: "参数错误"}, status: 400
    else
      message = Excel::DinnerSettleImporter.send(DinnerSettle::IMPORTOR_TYPE[params[:type]], attachment.file.url, params[:month])
      render json: message
    end
  end

  def compute
    if params[:month] && params[:type]
      is_success, messages = check_equal(params[:month])
      render json: {messages: messages} and return unless is_success

      if params[:type] == '饭卡数据'
        compute_meal_card(params[:month])
      elsif params[:type] == '重庆和昆明食堂数据'
        compute_cq_lm(params[:month])
      end
    else
      render json: {messages: "计算月份和类型是必须的参数"}, status: 400
    end
  end

  def export
    if params[:type]
      @filename = "#{params[:type]}.xls"
      @file_path = "#{Rails.root.to_s}/public/export/tmp/#{@filename}"
      Excel::DinnerSettleWriter.send(DinnerSettle::EXPORTOR_TYPE[params[:type]], params[:month], @file_path)
      send_file(@file_path, filename: @filename)
    else
      Notification.send_system_message(current_employee.id, {error_messages: '导出表类型是必须的参数'})
      return render text: ''
    end
  end

  # 历史记录
  def record
    if params[:do_export].present?
      # 导出文件
    end
  end

  private

  def check_equal(month)
    @north_part_amount = DinnerRecord.where(category: '北头明细', month: month).sum(:amount)
    @office_amount = DinnerRecord.where(category: '机关明细', month: month).sum(:amount)

    @north_part_stat = DinnerRecordStat.where(category: '北头总额', month: month).first
    @office_stat = DinnerRecordStat.where(category: '机关总额', month: month).first

    if !@north_part_stat
      return [false, "北头 #{month} 总额表未上传"]
    end

    if !@office_stat
      return [false, "机关 #{month} 总额表未上传"]
    end

    if @north_part_amount != (@north_part_stat.employee_charge_total + @north_part_stat.consume_total)
      return [false, "北头消费明细表累加交易额和总表消费总额+职工充值额不等，需要重新导入"]
    end

    if @office_amount != (@office_stat.employee_charge_total + @office_stat.consume_total)
      return [false, "机关消费明细表累加交易额和总表消费总额+职工充值额不等，需要重新导入"]
    end

    return [true, "明细表和总额表验证通过"]
  end

  def compute_meal_card(month)
    @dinner_record_stat = DinnerRecordStat.find_by(month: month, category: '机关总额')
    @airline_pos_list = @dinner_record_stat.airline_pos_list.map{|x|x.split("--")[1]}.uniq
    @political_pos_list = @dinner_record_stat.political_pos_list.map{|x|x.split("--")[1]}.uniq

    @dict_amount = {:north_part => {}, :office => {}}
    @config = DinnerPersonSetup.area_config
    @config.each do |key, hash|
      if key.include?("机关食堂")
        @dict_amount[:office] = {
          hash["breakfast_card_amount"].to_f => hash["breakfast_subsidy_amount"],
          hash["lunch_card_amount"].to_f => hash["lunch_subsidy_amount"],
          hash["dinner_card_amount"].to_f => hash["dinner_subsidy_amount"]
        }
      elsif key.include?("空勤食堂")
        @dict_amount[:airline] = {
          hash["breakfast_card_amount"].to_f => hash["breakfast_subsidy_amount"],
          hash["lunch_card_amount"].to_f => hash["lunch_subsidy_amount"],
          hash["dinner_card_amount"].to_f => hash["dinner_subsidy_amount"]
        }
      elsif key.include?("北头食堂")
        @dict_amount[:north_part] = {
          hash["breakfast_card_amount"].to_f => hash["breakfast_subsidy_amount"],
          hash["lunch_card_amount"].to_f => hash["lunch_subsidy_amount"],
          hash["dinner_card_amount"].to_f => hash["dinner_subsidy_amount"]
        }
      end
    end

    DinnerRecord.transaction do
      DinnerRecord.update_all(subsidy_amount: 0)

      @records = DinnerRecord.where(month: month, category: '北头明细', record_type: '固定扣款').find_in_batches do |group|
        group.each do |dr|
          dr.update(subsidy_amount: @dict_amount[:north_part][dr.amount.to_f].to_f)
        end
      end

      @records = DinnerRecord.where(month: month, category: '机关明细', record_type: '固定扣款', pos_no: @airline_pos_list).find_in_batches do |group|
        group.each do |dr|
          dr.update(subsidy_amount: @dict_amount[:airline][dr.amount.to_f].to_f)
        end
      end

      @records = DinnerRecord.where(month: month, category: '机关明细', record_type: '固定扣款', pos_no: @political_pos_list).find_in_batches do |group|
        group.each do |dr|
          dr.update(subsidy_amount: @dict_amount[:office][dr.amount.to_f].to_f)
        end
      end
    end

    # 饭卡编号总是有的，而且唯一，这里不能用employee_id，可能多个都是0
    @dr_hash = {}
    @values = []

    DinnerRecord.where(month: month).find_in_batches do |group|
      group.each {|record|@dr_hash[record.uniq_key] = record}
    end

    DinnerFee.where(month: month).find_in_batches do |group|
      group.each do |dps|
        @subsidy_amount = @dr_hash[dps.uniq_key].try(:subsidy_amount)
        @total = dps.card_amount + dps.working_fee + dps.backup_fee + @subsidy_amount
        @values << [month, dps.employee_id, dps.employee_no, dps.employee_name, dps.employee.try(:location), dps.shifts_type, dps.area, dps.card_amount, dps.card_number, dps.working_fee, dps.backup_fee, @subsidy_amount, @total]
      end
    end

    DinnerSettle.import(DinnerSettle::COLUMNS, @values, validate: false)
    @values.clear
  end

  # 重庆和昆明食堂数据
  def compute_cq_lm_dinning(month)
    #
  end
end
