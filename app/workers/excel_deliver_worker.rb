class ExcelDeliverWorker
  include Sidekiq::Worker
  include Connectable

  def perform(department_id, version)
    Department.connect_history_db(version) do
      department = Department.find(department_id)

      path = department.file_path
      departments = department.childrens
      Excel::DepartmentWriter.new(departments, path).write_excel
    end
  end
end
