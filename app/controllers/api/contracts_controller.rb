class Api::ContractsController < ApplicationController
  include ExceptionHandler

  def index
    result = parse_query_params!('contract')
    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?

    relations, conditions, sorts, page = result.values
    @contracts = Contract.joins(relations).order(start_date: :desc)

    conditions.each do |condition|
      @contracts = @contracts.where(condition)
    end

    if params[:show_merged] == "true"
      @contracts = @contracts.where(merged: false, original: false)
    else
      @contracts = @contracts.where(original: true)
    end

    @contracts = set_page_meta @contracts, page
  end

  def show
    @contract = Contract.find params[:id]
  end

  def create
    data = contract_params
    @employee = Employee.unscoped.find data[:employee_id]
    data[:employee_name]   = @employee.name
    data[:employee_no]     = @employee.employee_no
    data[:department_name] = @employee.department.full_name
    data[:position_name]   = EmployeePosition.full_position_name(@employee.employee_positions)
    data[:contract_no]     = data[:employee_no] if data[:contract_no].blank?
    data = judge_join_data data
    data[:employee_exists] = @employee.present? ? true : false

    if Contract.where(
        employee_id:   data[:employee_id],
        start_date:    Date.parse(data[:start_date]),
        end_date:      data[:end_date].present? ? Date.parse(data[:end_date]) : nil,
        apply_type:    data[:apply_type]
    ).present?
      render json: {messages: "重复合同数据"}, status: 400 and return
    end

    @contract = Contract.new(data)
    if @contract.save
      @contract.judge_merge_contract #merge contract

      if((@contract.apply_type == '合同' or @contract.apply_type == '合同制') and (@contract.change_flag == '转制' or @contract.change_flag == '新签'))
        category = @contract.change_flag == '转制' ? '合同转制' : '合同新签'
        hash = {employee_id: @employee.id, category: category, date: @contract.start_date}
        Publisher.broadcast_event('SOCIAL_CHANGE_INFO', hash)
      end

      if(%w(合同 合同制 公务员).include?(@contract.apply_type) and @contract.change_flag == '新签')
        hash = {employee_id: @employee.id, category: '合同新签', date: @contract.start_date, prev_channel_id: @employee.channel_id_was}
        Publisher.broadcast_event('SALARY_CHANGE', hash)
      end

      @employee.change_info_by_contract(@contract) if @contract.change_flag == "转制"
      Notification.send_user_message(@employee.id, "general", "你可于下月开始，加入川航企业年金，请在员工自助，我的申请中点击企业年金，进行了解和申请。") if @contract.apply_type == "合同制" && @contract.change_flag == "转制"
      render template: '/api/contracts/show'
    else
      render json: {messages: @contract.errors.values.flatten.join(",")}, status: 400
    end
  end

  def update
    @contract = Contract.find(params[:id])
    @employee = @contract.employee

    if @contract.update(contract_update_params)
      if((@contract.apply_type == '合同' or @contract.apply_type == '合同制') and (@contract.change_flag == '转制' or @contract.change_flag == '新签'))
        category = @contract.change_flag == '转制' ? '合同转制' : '合同新签'
        hash = {employee_id: @employee.id, category: category, date: @contract.start_date}
        Publisher.broadcast_event('SOCIAL_CHANGE_INFO', hash)
      end

      if(%w(合同 合同制 公务员).include?(@contract.apply_type) and @contract.change_flag == '新签')
        hash = {employee_id: @employee.id, category: '合同新签', date: @contract.start_date, prev_channel_id: @employee.channel_id_was}
        Publisher.broadcast_event('SALARY_CHANGE', hash)
      end

      if @contract.apply_type == "合同制" && @contract.change_flag == "转制"
        Notification.send_user_message(@employee.id, "general", "你可于下月开始，加入川航企业年金，请在员工自助，我的申请中点击企业年金，进行了解和申请。")
      end

      @employee.change_info_by_contract(@contract) if @contract.change_flag == "转制"

      Contract.remerge_contract(@employee.id)

      render json: {messages: '合同更新成功'}
    else
      render json: {messages: @contract.errors.values.flatten.join(",")}, status: 400
    end
  end

  def import
    # 导入合同数据
    attachment = Attachment.find(params[:attachment_id])

    if %w(xls xlsx).exclude?(attachment.file_type.downcase)
      return render json: {messages: "对不起，目前仅支持xls和xlsx文件导入"}, status: 400
    end

    importer = Excel::ContractImporter.new(attachment.full_path)

    importer.parse_data

    if importer.errors.present?
      render json: {messages: importer.errors}, status: 400  and return
    end

    importer.import_contract

    render json: {messages: '导入成功'}
  end

  private
  def contract_update_params
    safe_params([:change_flag, :start_date, :end_date, :due_time, :notes, :is_unfix, :apply_type])
  end

  def contract_params
    safe_params([
      :contract_no, :employee_id, :apply_type, :change_flag, :start_date,
      :end_date,    :due_time,    :status,     :notes,       :is_unfix
    ])
  end

  def judge_join_data data
    case data[:change_flag]
    when "新签"
      data[:join_date] = data[:start_date]
    else
      data[:join_date] = Contract.where(employee_id: data[:employee_id]).minimum(:join_date)
    end
    data
  end
end
