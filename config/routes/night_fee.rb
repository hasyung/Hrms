resources :night_fees do
  collection do
    post :import
    get :compute
    get :export
  end
end
