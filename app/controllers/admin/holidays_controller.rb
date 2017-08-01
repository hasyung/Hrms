class Admin::HolidaysController < AdminController
  def index
    @holidays = Holiday.order(record_date: :asc)
    @holidays = @holidays.where("record_date >= '#{params[:start_date]}'") unless params[:start_date].blank?
    @holidays = @holidays.where("record_date <= '#{params[:end_date]}'") unless params[:end_date].blank?
    @holidays = @holidays.paginate(page: params[:page] || 1, per_page: params[:per_page] || 10)
  end

  def destroy
    @holiday = Holiday.find params[:id]
    if @holiday.destroy
      flash[:notice] = '删除成功'
    else
      flash[:error] = '删除失败'
    end

    redirect_to admin_holidays_path
  end

  def new
    @holiday = Holiday.new()
  end

  def create
    if Holiday.where(record_date: holiday_params[:record_date]).present?
      flash[:error] = '该日期已经是节假日，不能重复添加'
      redirect_to action: 'index' and return
    end

    @holiday = Holiday.new(
      holiday_params.merge!( { flag: 2, is_custom: true })
    )

    if @holiday.save
      redirect_to action: 'index'
    else
      render action: 'new'
    end
  end

  private
  def holiday_params
    params.require(:holiday).permit(:record_date, :note)
  end
end
