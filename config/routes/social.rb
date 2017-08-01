resources :social_person_setups

resources :social_records, only: [:index] do
  collection do
    post :import
    get  :compute
    get :export_record
    get :export_declare
    get :export_withhold
  end
end

resources :social_change_infos, only: [:index, :show, :update]