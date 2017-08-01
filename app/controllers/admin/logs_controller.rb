class Admin::LogsController < AdminController
  def index
    @logs = Log.all.paginate(:page => params[:page], :per_page => 20).order('created_at DESC')
  end

  def show
    @log = Log.find params[:id]
  end
end
