resources :contracts do
  collection do
    post :import
  end
end

resources :agreements, only: [:show, :index, :create, :update]
