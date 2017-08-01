resources :vacations do
  collection do
    get :summary
    get :calc_days
    post :import_annual_days
  end
end
