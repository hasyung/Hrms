class Api::SetBooksController < ApplicationController
  before_action :set_employee, except: [:export_change_record]

  def info
    @set_book_info = @employee.set_book_info
    render json: {messages: "该员工套账信息为空"} and return unless @set_book_info.present?
    render template: 'api/set_books/show'
  end

  def create
    @set_book_info = @employee.build_set_book_info(info_params)
    if @set_book_info.generate_change_record("create", info_params)
      @employee.update(salary_set_book: @set_book_info.salary_category)
      render template: 'api/set_books/show'
    else
      render json: {messages: '创建失败'}, status: 400
    end
  end

  def update
    @set_book_info = @employee.set_book_info
    if @set_book_info.generate_change_record("update", info_params)
      @employee.update(salary_set_book: @set_book_info.salary_category)
      render template: 'api/set_books/show'
    else
      render json: {messages: '更新失败'}, status: 400
    end
  end

  def export_change_record
    excel = Excel::SetBookExportor.export_change_record
    send_file(excel[:path], filename: excel[:filename])
  end

  private
  def set_employee
    @employee = Employee.includes(:department).find params[:employee_id]
  end

  def info_params
    params.permit(
      :bank_no, :salary_category, :employee_category
    )
  end
end
