class Api::BirthSalariesController < ApplicationController
  include ExceptionHandler

  def compute
    if params[:month]
      message = SalaryPersonSetup.check_compute(params[:month])
      return render json: {birth_salaries: [], messages: message} if message

      is_success, messages = BirthSalary.compute(params[:month])
      return render json: {birth_salaries: [], messages: messages || "计算发生错误"}, status: 400 if !is_success

      @birth_salaries = BirthSalary.joins(employee: :department).order(
        "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
        ).where("birth_salaries.month = '#{params[:month]}'")
      page = parse_query_params!("birth_salary").values.last
      @birth_salaries = set_page_meta(@birth_salaries, page)
      render template: 'api/birth_salaries/index'
    else
      render json: {messages: "条件不足"}, status: 400
    end
  end

  def index
    result = parse_query_params!('birth_salary')
    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
    relations, conditions, sorts, page = result.values

    @birth_salaries = BirthSalary.joins(employee: :department).joins(relations).order(
      "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
    ).order(sorts)

    conditions.each do |condition|
      @birth_salaries = @birth_salaries.where(condition)
    end
    @birth_salaries = set_page_meta @birth_salaries, page
  end
end