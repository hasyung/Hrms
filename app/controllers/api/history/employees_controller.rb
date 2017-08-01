class Api::History::EmployeesController < ApplicationController
  include ExceptionHandler

  def index
    log = DepartmentChangeLog.find_by(id: params[:version])
    if log
      Employee.connect_history_db(params[:version]) do
        employees = Employee.includes(:gender, :education_background, :political_status, :contact)
          .joins(:employee_positions).where('employee_positions.position_id = ?', params[:position_id])
        render json: {
          employees: employees.inject([]) do |result, employee|
            result << {
              id: employee.id,
              name: employee.name,
              employee_no: employee.employee_no,
              identity_no: employee.identity_no,
              gender: employee.gender,
              education_background: employee.education_background,
              political_status: employee.political_status,
              contact: employee.contact
            }
          end
        }
      end
    else
      render json: {messages: "资源不存在"}, status: 404
    end
  end
end
