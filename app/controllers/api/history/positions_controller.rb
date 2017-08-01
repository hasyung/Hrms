class Api::History::PositionsController < ApplicationController
  include ExceptionHandler

  def index
    log = DepartmentChangeLog.find_by(id: params[:version])
    if log
      Position.connect_history_db(params[:version]) do
        positions = Position.includes(:channel, :category, :position_nature, :specification)
                    .where(department_id: params[:department_id])
        department = Department.find_by(id: params[:department_id])
        render json: {
          positions: positions.inject([]) do |result, position|
            result << {
              id: position.id,
              name: position.name,
              post_type: position.post_type,
              budgeted_staffing: position.budgeted_staffing,
              staffing: position.staffing,
              oa_file_no: position.oa_file_no,
              channel: position.channel,
              category: position.category,
              position_nature: position.position_nature,
              created_at: position.created_at,
              specification: position.specification,
              department: {
                id: department.id,
                name: department.name
              }
            }
          end
        }
      end
    else
      render json: {messages: "资源不存在"}, status: 404
    end
  end

  def formerleaders
    log = DepartmentChangeLog.find_by(id: params[:version])
    if log
      Position.connect_history_db(params[:version]) do
        position = Position.find_by(id: params[:id])
        if position
          former_leaders = position.former_leader_snapshot
          if former_leaders
            render json: {
              employees: former_leaders.inject([]) do |result, former_leader|
                result << {
                  id: former_leader[:id],
                  employee: {
                    name: former_leader[:employee_name]
                  },
                  employee_no: former_leader[:employee_no],
                  start_date: former_leader[:start_date],
                  end_date: former_leader[:end_date],
                  remark: former_leader[:remark]
                }
              end
            }
          else
            return render json: {messages: "该岗位不是领导岗位", employees: []}, status: 400
          end
        else
          return render json: {messages: "该岗位不存在", employees: []}, status: 400
        end
      end
    else
      render json: {messages: "资源不存在"}, status: 404
    end
  end

end
