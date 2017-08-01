resources :calc_steps, only: [:show, :index] do
  collection do
    get :search
  end
end