resources :reports, except: [:new, :edit] do
  collection do
    get :need_to_know
  end
end
