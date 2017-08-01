class Api::DinnerChangesController < ApplicationController
  def index
    @dinner_changes = DinnerChange.includes(employee: [:department, :category])

    page = parse_query_params!("dinner_change").values.last
    @dinner_changes = set_page_meta(@dinner_changes, page)

    @form_data = Welfare.find_by(category: 'dinners').form_data
    @areas = []

    if @form_data.present?
      @form_data[0]['chengdu_head_office'].each do |dict|
        @areas << dict['areas']
      end

      @form_data[1]['chengdu_north_part'].each do |dict|
        @areas << dict['areas']
      end

      @form_data[2]['others'].each do |dict|
        @areas << dict['cities']
      end
    end
    @areas.flatten!.uniq!
  end

  def destroy
    @dinner_change = DinnerChange.find(params[:id])
    @dinner_change.destroy if @dinner_change
    render json: {messages: '删除成功'}
  end

  def show
    @dinner_change = DinnerChange.find(params[:id])
    @dinner_person_setups = DinnerPersonSetup.where(employee_id: @dinner_change.employee_id)
    @is_suspend = false
    @is_suspend = true if @dinner_person_setups.present? && @dinner_person_setups.select{|s| s.is_suspend}.size == @dinner_person_setups.size
  end

  def update
    @dinner_change = DinnerChange.find(params[:id])
    return render json: {messages: '该员工已离职'}, status: 400 unless @dinner_change.employee
    
    file_path = "#{Rails.root.to_s}/public/export/"
    zip_filename = "Info#{Time.new.strftime("%Y%m%d")}_#{@dinner_change.employee.name}工作餐变动.zip"
    input_filenames = []

    DinnerChange.transaction do
      if %w(新进员工 岗位变动 属地变动).include?(@dinner_change.category)
        return render json: {messages: "参数错误"}, status: 400 if params[:dinner_person_setups].blank?

        if @dinner_change.category == '新进员工'
          money_setups = params[:dinner_person_setups].select{|s| ["机关食堂", "空勤食堂", "北头食堂"].exclude?(s['area'])}
          if money_setups.present?
            return render json: {messages: "参数错误"}, status: 400 if money_setups.size > 1
            dinner_person_setup = DinnerPersonSetup.new(money_setups.first)
            dinner_person_setup.change_date = @dinner_change.change_date

            dinner_person_setup.change_newbie

            unless dinner_person_setup.save
              return render json: {messages: dinner_person_setup.errors.full_messages.join(",")}, status: 400
            end
          else
            if @dinner_change.employee.category.try(:display_name) == "干部"
              if params[:dinner_person_setups].select{|s| ["空勤食堂", "北头食堂"].include?(s['area'])}.inject{|sum, x|sum + x['card_amount']}.to_f > 150
                return render json: {messages: "空勤干部在空勤食堂和北头食堂总额不能超过150"}, status: 400
              end
            end
            jiguan = params[:dinner_person_setups].select{|s| ["空勤食堂", "机关食堂"].include?(s['area'])}
            beitou = params[:dinner_person_setups].select{|s| s['area'] == "北头食堂"}
            return render json: {messages: "参数错误"}, status: 400 if jiguan.size > 1 || beitou.size > 1

            params[:dinner_person_setups].each do |setup|
              dinner_person_setup = DinnerPersonSetup.new(setup)
              dinner_person_setup.change_date = @dinner_change.change_date
              dinner_person_setup.change_newbie

              if dinner_person_setup.save
                input_filenames << create_change_file(dinner_person_setup)
              else
                return render json: {messages: dinner_person_setup.errors.full_messages.join(",")}, status: 400
              end
            end unless params[:dinner_person_setups].blank?
          end
        else %w(岗位变动 属地变动).include?(@dinner_change.category)
          if @dinner_change.employee.category.try(:display_name) == "干部"
            if params[:dinner_person_setups].select{|s| ["空勤食堂", "北头食堂"].include?(s['area'])}.inject{|sum, x|sum + x['card_amount']}.to_f > 150
              return render json: {messages: "空勤干部在空勤食堂和北头食堂总额不能超过150"}, status: 400
            end
          end

          jiguan = params[:dinner_person_setups].select{|s| ["空勤食堂", "机关食堂"].include?(s['area'])}
          beitou = params[:dinner_person_setups].select{|s| s['area'] == "北头食堂"}
          return render json: {messages: "参数错误"}, status: 400 if jiguan.size > 1 || beitou.size > 1

          params[:dinner_person_setups].each do |setup|
            dinner_person_setup = DinnerPersonSetup.find_by(id: setup['id'])

            if dinner_person_setup
              if setup['area'] != dinner_person_setup.area
                return render json: {messages: "参数错误"}, status: 400 if params[:dinner_person_setups].size > 1

                new_record = DinnerPersonSetup.new(setup)
                new_record.change_date = dinner_person_setup.change_date = @dinner_change.change_date
                # 工作地点调整
                dinner_person_setup.change_location(new_record)
                if dinner_person_setup.save && new_record.save
                  input_filenames << create_change_file(dinner_person_setup, '修改资料')
                  input_filenames << create_change_file(new_record)
                else
                  return render json: {messages: dinner_person_setup.errors.full_messages.join(",")}, status: 400
                end
              elsif dinner_person_setup.shifts_type != setup['shifts_type']
                dinner_person_setup.assign_attributes(setup)
                dinner_person_setup.change_date = @dinner_change.change_date
                # 班制调整
                dinner_person_setup.change_shifts_type
                if dinner_person_setup.save
                  input_filenames << create_change_file(dinner_person_setup, '修改资料')
                else
                  return render json: {messages: dinner_person_setup.errors.full_messages.join(",")}, status: 400
                end
              else
                dinner_person_setup.assign_attributes(setup)
                dinner_person_setup.change_date = @dinner_change.change_date
                if dinner_person_setup.save
                  input_filenames << create_change_file(dinner_person_setup, '修改资料')
                else
                  return render json: {messages: dinner_person_setup.errors.full_messages.join(",")}, status: 400
                end
              end
            else
              dinner_person_setup = DinnerPersonSetup.new(setup)
              dinner_person_setup.change_date = @dinner_change.change_date
              dinner_person_setup.change_newbie
              if dinner_person_setup.save
                input_filenames << create_change_file(dinner_person_setup)
              else
                return render json: {messages: dinner_person_setup.errors.full_messages.join(",")}, status: 400
              end
            end
          end
        end
      else
        dinner_person_setups = DinnerPersonSetup.where(employee_id: @dinner_change.employee_id)
        dinner_person_setups.update_all(params.permit(:is_suspend, :change_date)) if dinner_person_setups.present?
      end
    end

    @dinner_change.update(params.permit(:state))
    if input_filenames.present?
      File.creation_zip_file(file_path, zip_filename, input_filenames)
      send_file(file_path + zip_filename, filename: zip_filename)
    else
      render json: {messages: '处理成功'}
    end
  end

  private

  def create_change_file(dinner_person_setup, category = '新增')
    filename = "Info#{Time.new.strftime("%Y%m%d")}_#{dinner_person_setup.area.gsub("食堂", "")}.xls"
    file_path = "#{Rails.root.to_s}/public/export/tmp/#{filename}"

    change_data = {
      Bzje: dinner_person_setup.card_amount,
      Bzcs_Zc: dinner_person_setup.breakfast_number,
      Bzcs_Zw: dinner_person_setup.lunch_number,
      Bzcs_Ws: dinner_person_setup.dinner_number,
      Bzcs_Yx: 0
    }

    dinner_person_setup.generate_change_xls(category, file_path, change_data)
    filename
  end
end
