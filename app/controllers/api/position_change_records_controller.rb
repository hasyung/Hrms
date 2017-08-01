class Api::PositionChangeRecordsController < ApplicationController
  def index
    result = parse_query_params!('position_change_record')
    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
    relations, conditions, sorts, page = result.values

    @position_change_records = PositionChangeRecord.joins(:employee)
      .includes(:employee, employee: :department, employee: :positions)
      .order("position_change_date asc")
      .where(is_finished: false)

    conditions.each do |condition|
      @position_change_records = @position_change_records.where(condition)
    end

    @position_change_records = set_page_meta @position_change_records, page
  end

  def batch_create
    return render json: {messages: "岗位数据不能为空"}, status: 400 if position_form.empty?
    return render json: {messages: "人员主岗不能为空"}, status: 400 if position_form.select{|pos_params| pos_params[:category] == '主职'}.count == 0

    PositionChangeRecord.transaction do
      params[:employee_ids].each do |employee_id|
        @position_change_recrod = PositionChangeRecord.new(
          permited_params.merge(
            position_form: position_form,
            operator_name: current_employee.name,
            operator_id: current_employee.id,
            employee_id: employee_id
          )
        )

        if @position_change_recrod.valid?
          if @position_change_recrod.check_diff || @position_change_recrod.check_position_remark
            @position_change_recrod.save
            if @position_change_recrod.position_change_date <= Date.today
              @position_change_recrod.active_change!
            end
          else
            render json: {messages: "员工信息没有改变"}, status: 400
          end
        else
          render json: {messages: @position_change_recrod.errors.messages}, status: 400
        end
      end
    end
    render json: {messages: '岗位异动记录创建成功'}
  end

  def create
    return render json: {messages: "岗位数据不能为空"}, status: 400 if position_form.empty?
    return render json: {messages: "人员主岗不能为空"}, status: 400 if position_form.select{|pos_params| pos_params[:category] == '主职'}.count == 0

    @position_change_recrod = PositionChangeRecord.new(
      permited_params.merge(
        position_form: position_form,
        operator_name: current_employee.name,
        operator_id: current_employee.id
      )
    )

    if @position_change_recrod.valid?
      if @position_change_recrod.check_diff || @position_change_recrod.check_position_remark
        @position_change_recrod.save
        if @position_change_recrod.position_change_date <= Date.today
          @position_change_recrod.active_change!
          # ChangeRecordWeb.save_record("employee_special", Employee.find_by(id: params[:employee_id])).send_notification
          render json: {messages: '岗位异动记录创建成功, 员工相关信息已经自动变更'}
        else
          # ChangeRecordWeb.save_record("employee_special", Employee.find_by(id: params[:employee_id])).send_notification
          render json: {messages: '岗位异动记录创建成功，员工相关信息在调岗日期到来后将自动调整'}
        end
      else
        render json: {messages: "员工信息没有改变"}, status: 400
      end
    else
      render json: {messages: @position_change_recrod.errors.messages}, status: 400
    end
  end

  def destroy
    @position_change_record = PositionChangeRecord.find(params[:id])
    @position_change_record.destroy

    render json: {messages: '撤销成功'}
  end

  private
  def permited_params
    params.permit(
      :channel_id, :employee_id, :category_id, :duty_rank_id, :position_remark,
      :oa_file_no, :position_change_date, :probation_duration, :classification,
      :location
    )
  end

  def position_form
    handled_pos_params = []
    return handled_pos_params  if params[:positions].blank?

    params[:positions].each_with_index do |pos_params, index|
      handled_pos_params << {
        position_id: pos_params[:position][:id],
        category: pos_params[:category],
        sort_index: "#{index}",
        department_id: pos_params[:department][:id]
      }
    end
    handled_pos_params
  end
end
