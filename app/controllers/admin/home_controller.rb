class Admin::HomeController < AdminController
  def index
    @admins = Employee.unscoped.where(is_admin: true)
    @employee_count = Employee.count
  end

  def run_async_task
    FutureTask.new.perform()
    flash[:notice] = "已触发~~"
    redirect_to "/crontask" and return
  end
end
