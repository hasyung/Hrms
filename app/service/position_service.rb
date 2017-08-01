class PositionService
  def initialize(params, current_employee)
    @params = params
    @current_employee = current_employee
  end

  def get_positions
    positions = Position.not_confirmed.includes(:channel,:employee_positions, :schedule, :department).joins(
      "JOIN departments ON positions.department_id = departments.id"
    ).order(
      "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, positions.sort_no"
    )

    if !(@current_employee.hr? and !@current_employee.department_hr?) and !@current_employee.company_leader?
      department_ids = @current_employee.get_departments_for_role
      if department_ids.present?
        positions = positions.joins(:employees).where(
          "positions.department_id in (?) or employees.id = #{@current_employee.id}", department_ids)
      else
        positions = positions.joins(:employees).where("employees.id = #{@current_employee.id}")
      end
    end

    positions = (query_params.empty? ? positions : positions.query(query_params)).uniq
  end

  private
  def query_params
    Setting.query_rule.position.sql.keys.inject({}) do |query_params, key|
      query_params[key] = @params[key] if @params[key]
      query_params
    end
  end
end
