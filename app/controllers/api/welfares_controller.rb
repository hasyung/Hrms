class Api::WelfaresController < ApplicationController
  include ExceptionHandler

  def show
    welfare = Welfare.find_by(category: params[:category])
    if welfare && welfare.category == 'socials'
      @socials = welfare.form_data
      render template: 'api/welfares/socials'
    elsif welfare && welfare.category == 'dinners'
      @dinners = welfare.form_data
      puts @dinners
      render template: 'api/welfares/dinners'
    else
      render json: {messages: "参数错误"}, status: 400
    end
  end

  def update_socials
    welfare = Welfare.find_by(category: params[:category])

    if welfare && welfare.category == 'socials'
      welfare.assign_attributes(form_data: params[:socials])

      if welfare.save
        @socials = welfare.form_data
        render template: 'api/welfares/socials'
      else
        render json: {messages: welfare.errors.values.flatten.join(",")}, status: 400
      end
    elsif welfare && welfare.category == 'dinners'
      welfare.assign_attributes(form_data: params[:dinners])

      if welfare.save
        @dinners = welfare.form_data
        render template: 'api/welfares/dinners'
      else
        render json: {messages: welfare.errors.values.flatten.join(",")}, status: 400
      end
    else
      render json: {messages: "参数错误"}, status: 400
    end
  end

  def update_dinners
    welfare = Welfare.find_by(category: params[:category])

    if welfare && welfare.category == 'socials'
      welfare.assign_attributes(form_data: params[:socials])

      if welfare.save
        @socials = welfare.form_data
        render template: 'api/welfares/socials'
      else
        render json: {messages: welfare.errors.values.flatten.join(",")}, status: 400
      end
    elsif welfare && welfare.category == 'dinners'
      welfare.assign_attributes(form_data: params[:dinners])

      if welfare.save
        @dinners = welfare.form_data
        render template: 'api/welfares/dinners'
      else
        render json: {messages: welfare.errors.values.flatten.join(",")}, status: 400
      end
    else
      render json: {messages: "参数错误"}, status: 400
    end
  end
end
