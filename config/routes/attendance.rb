resources :attendances do
  collection do
    get :employees
    get :history
    get :approve
    get :leave_list
    get :summary
    get :summary_history
  end
end
