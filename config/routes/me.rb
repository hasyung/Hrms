scope module: 'me' do
  resource :me, only: [:show, :update] do
    get :resume
    get :leave
    get :alleges
    get "/alleges/:id", to: "/api/performance_alleges#show"
    get :performances
    get :export_resume
    get :annuities
    get :punishments
    get :rewards
    get :auditor_list
    get :attendance_records
    get :technical_records

    put :update_password
    put :upload_favicon

    resources :familymembers, :education_experiences, :work_experiences, except: [:show]

    resources :notifications, only: [:index] do
      put :update, on: :collection
    end

    resources :todos, only: [:index, :show]
    resources :flow_contact_people, only: [:index, :create, :destroy]

    get "/workflows/:flow_type", to: "workflows#index"
    get "/workflows/:flow_type/:id", to: "workflows#show"
  end
end
