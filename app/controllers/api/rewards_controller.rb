class Api::RewardsController < ApplicationController
  include ExceptionHandler

  def index
    result = parse_query_params!('reward')
    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
    relations, conditions, sorts, page = result.values

    @rewards = Reward.joins(employee: :department).joins(relations).order(
      "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
    ).order(sorts)

    conditions.each do |condition|
      @rewards = @rewards.where(condition)
    end

    @rewards = set_page_meta(@rewards, page)
  end

  def compute
    if params[:month]
      message = SalaryPersonSetup.check_compute(params[:month])
      return render json: {rewards: [], messages: message} if message

      is_success, messages = Reward.compute(params[:month])
      return render json: {rewards: [], messages: messages || "计算发生错误"}, status: 400 if !is_success

      @rewards = Reward.joins(employee: :department).order(
        "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
      ).where("rewards.month = '#{params[:month]}'")

      page = parse_query_params!("reward").values.last
      @rewards = set_page_meta(@rewards, page)

      render template: 'api/rewards/index'
    else
      render json: {messages: messages || "计算发生错误"}, status: 400 if !is_success
    end
  end

  def update
    @reward = Reward.find(params[:id])

    if @reward.update(reward_params)
      render template: '/api/rewards/show'
    else
      render json: {messages: '修改失败'}, status: 400
    end
  end

  def import
    @type = Reward::IMPORTOR_TYPE[params[:type]]
    attachment = Attachment.find_by(id: params[:attachment_id])

    if %w(xls xlsx).exclude?(attachment.file_type.downcase)
      return render json: {messages: "对不起，目前仅支持xls和xlsx文件导入"}, status: 400
    end

    if attachment.blank? || params[:month].blank? ||
        params[:type].blank? || Reward::IMPORTOR_TYPE[params[:type]].blank?
      return render json: {messages: "参数错误"}, status: 400
    else
      message = Excel::RewardImporter.import(@type, attachment.file.url, params[:month])
      if message[:is_succ]
        render json: message[:result]
      else
        render json: message[:result], status: 400
      end
    end
  end

  def export_nc
    if(params[:month])
      rewards = Reward.joins(employee: :department).order(
        "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
        ).where("rewards.month = '#{params[:month]}'")
      if rewards.blank?
        Notification.send_system_message(current_employee.id, {error_messages: '导出数据为空'})
        return render text: ''
      end
      excel = Excel::RewardExportor.export_nc(rewards, params[:month])
      send_file(excel[:path], filename: excel[:filename])
    else
      Notification.send_system_message(current_employee.id, {error_messages: '条件不足'})
      render text: ''
    end
  end

  def export_approval
  end

  private
  def reward_params
    params.permit(:add_garnishee, :remark)
  end
end
