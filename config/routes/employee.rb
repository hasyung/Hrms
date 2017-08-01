resources :employees do
  collection do
    post :import
    post :import_family_members
    post :transfer_to_regular_worker

    get :export_to_xls
    get :export_resume
    get :permissions
    get :avatar_url
    post :work_experience_import

    get :search
    get :simple_index
    get :flow_leader_index
    post :star_import
  end

  member do
    get :resume
    get :performances
    get :family_members
    get :show_basic_info
    get :show_skill_info
    get :show_position_info
    get :attendance_records
    get :technical_records
    post :set_early_retire
    post :change_technical

    put :performance_info
    put :update_basic_info
    put :update_position_info
    put :update_skill_info
    put :update_technical_grade

    post :change_education
    post :set_leave
    post :set_offset_days
    post :set_employee_date

    get  'punishments', to: "punishments#index"
    get  'rewards',     to: "punishments#index"
    post 'punishments', to: "punishments#create"
    post 'rewards',     to: "punishments#create"
  end
end

resource :employee_changes, only: [:update] do
  get :check
  get :record
end

resources :employee_changes, only: [:show]
get "/employee_changes/check/:id", to: "employee_changes#show"
get "/employee_changes/record/:id", to: "employee_changes#show"

resources :leave_employees, only: [:index, :update, :show] do
  get :export_to_xls, on: :collection
end

resources :early_retire_employees, only: [:index, :update, :show] do
  get :export_to_xls, on: :collection
end

resources :special_states, only: [:index, :update, :show] do
  collection do
    post :temporarily_transfer
    post :temporarily_defend
    post :temporarily_train
    post :temporarily_stop_air_duty
    post :temporarily_business_trip
    get :export_xls
  end
end

resources :education_experience_records, only: [:index] do
  get :export_to_xls, on: :collection
end
