class Api::EmployeeChangesController < ApplicationController
  include ExceptionHandler

  skip_before_action :check_action_register, only: [:show]
  skip_before_action :check_permission, only: [:show]

  def check
    @audits = Audit.employee_check
    @audits = set_page_meta @audits, get_page
    render template: '/api/employee_changes/index'
  end

  def show
    @audit = Audit.find(params[:id])
    render template: '/api/employee_changes/show'
  end

  def record
    result = parse_query_params!('employee_audit')
    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
    relations, conditions, sorts, page = result.values
    audit_conditions, employee_conditions = [], []
    conditions.each{|condition|condition[0].include?('audits') ? audit_conditions << condition : employee_conditions << condition}
    if employee_conditions.blank?
      @audits = Audit.employee_record
    else
      employees = Employee.unscoped.joins(relations)
      employee_conditions.each{|condition| employees = employees.where(condition)}
      employee_ids = employees.map(&:id)
      @audits = Audit.employee_record.where("(auditable_type = 'Employee' AND auditable_id in (?)) OR (associated_type = 'Employee' AND associated_id in (?))", employee_ids, employee_ids).order(sorts)
    end
    audit_conditions.each do |condition|
      if condition[0].include?('auditable_type')
        condition[1] = Audit::EMPLOYEE_TYPES[condition[1]]
      end
      @audits = @audits.where(condition)
    end unless audit_conditions.blank?
    @audits = set_page_meta @audits, page
    render template: '/api/employee_changes/index'
  end

  def update
    @audits = []

    params[:audits].each do |param|
      audit = Audit.find_by(id: param['id'])
      audit.update(audit_params(param)) if audit
      @audits << audit if audit
    end if params[:audits]

    if @audits.present?
      render template: '/api/employee_changes/index'
    else
      render json: {messages: '参数有误'}, status: 400
    end
  end

  private
  def audit_params audit
    audit.permit(:reason, :status_cd).merge!({check_date: Date.current})
  end

  def get_page
    page = {}
    page_params = {page: params.delete("page"), per_page: params.delete("per_page")}
    if page_params["page"].present?
      page[:page] = page_params["page"].to_i
    else
      page[:page] = QuerySetting['default']['page']
    end
    if page_params["per_page"].present?
      page[:per_page] = page_params["per_page"].to_i
    else
      page[:per_page] = QuerySetting['default']['per_page']
    end
    page
  end
end
