resources :dinner_person_setups do
  collection do
    post :import
    get :compute
    get :export_xls
    get :load_config
    post :batch_delete
  end
end