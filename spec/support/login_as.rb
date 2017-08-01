module LoginAs
  def login_as_user(employee_id)
    @current_employee = Employee.find(employee_id)
    @access_token = @current_employee.authenticate_tokens.generate_token
    cookies[:token] = @access_token.token
  end
end
