resources :statements, only: [] do
  collection do
    get :new_leave_employee_info
    get :new_leave_employee_summary
    get :position_change_record_pie
    get :position_change_record_channel
  end
end
