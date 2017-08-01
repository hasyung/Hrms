resources :dinner_settles do
  collection do
    post :import
    get :compute
    get :export
    get :record # 历史记录
  end
end
