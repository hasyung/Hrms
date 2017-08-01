class Api::AnnuityApplyController < ApplicationController
  include ExceptionHandler

  def index
    result = parse_query_params!('annuity_apply')
    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
    relations, conditions, sorts, page = result.values

    @annuity_applies = AnnuityApply.includes([]).joins(relations).where(status: false).order(created_at: "DESC")

    conditions.each do |condition|
      @annuity_applies = @annuity_applies.where(condition)
    end

    @annuity_applies = set_page_meta @annuity_applies, page
  end

  def apply_for_annuity
    @employee_labor_relation = Employee::LaborRelation.where(display_name: '合同制').first

    message = "申请退出"
    if params[:status] == 'true'
      message = "申请加入"
      if current_employee.labor_relation_id != @employee_labor_relation.id
        render json: {messages: '只能合同制员工可以申请加入年金'}, status: 400 and return
      end
      if current_employee.contact.try(:mobile).blank?
        render json: {messages: '加入企业年金必须登记手机号码'}, status: 400 and return
      end
    end

    apply =  current_employee.annuity_applies.new(
      employee_name:     current_employee.name,
      employee_no:       current_employee.employee_no,
      department_name:   current_employee.department.full_name,
      apply_category:    message,
      status:            false
    )

    if apply.save
      render json: {messages: '申请成功'}
    else
      render json: {messages: '申请失败', errors: apply.errors.values.flatten.join(",")}, status: 400
    end
  end

  def handle_apply
    #handle_status =  加入 (加入年金计划) || 退出 (退出年金计划)
    if params[:handle_status].blank? || !["加入", "退出"].include?(params[:handle_status])
      render json: {messages: "参数错误"}, status: 400 and return
    else
      handle_status = params[:handle_status] == "加入" ? true : false
      apply = AnnuityApply.find params[:id]
      apply.handle(handle_status)

      render json: {messages: '处理成功'}
    end
  end
end
