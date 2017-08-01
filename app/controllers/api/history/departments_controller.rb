class Api::History::DepartmentsController < ApplicationController
  include ExceptionHandler

  skip_before_action :check_action_register, only: [:export_to_xls]
  skip_before_action :check_permission, only: [:export_to_xls]

  def index
    log = DepartmentChangeLog.find_by(id: params[:version])
    if log
      Department.connect_history_db(params[:version]) do
        departments = Department.includes(:grade, :nature)
        render json: {
          departments: (departments.inject([]) do |result, department|
            result << {
              id: department.id,
              name: department.name,
              grade: department.grade,
              parent_id: department.parent_id,
              nature_id: department.nature_id,
              serial_number: department.serial_number,
              nature: department.nature,
              status: "active",
              xdepth: department.depth,
              sort_no: department.sort_no,
              is_stick: department.is_stick,
              committee: department.respond_to?(:committee) ? department.committee : department.committee?
            }
          end),
          meta: log
        }
      end
    else
      render json: {messages: "资源不存在"}, status: 404
    end
  end

  def export_to_xls
    log = DepartmentChangeLog.find_by(id: params[:version])
    if log
      Department.connect_history_db(params[:version]) do
        department = Department.find(params[:department_id])

        if department.exist_excel?
          send_file(department.file_path, filename: department.filename)
        else
          Excel::DepartmentWriter.new([department], department.file_path).write_excel
          send_file(department.file_path, filename: department.filename)
        end
      end
    else
      Notification.send_system_message(current_employee.id, {error_messages: '你访问的资源不存在'})
      render text: ''
    end
  end

end
