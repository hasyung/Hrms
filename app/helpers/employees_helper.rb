module EmployeesHelper
  def default_favicon(employee, version)
    "/assets/default/employees/favicons/#{employee.gender.try(:en_name) == 'male' ? 'male' : 'female'}_#{version}_default.png"
  end

  def get_favicon(employee, version)
    if employee.favicon.present?
      Setting.upload_url + employee.favicon.try(version).url
    else
      Setting.upload_url + default_favicon(employee, version)
    end
  end

  def get_favicons(employee_ids, version)
    Employee.find(employee_ids).map do |employee|
      get_favicon(employee, version)
    end
  end
end