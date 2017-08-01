resources :performances, only: [:index, :update] do
  collection do
    get :temp
    get :temp_export

    post :import_performances
    post :import_month_distribute_base
    post :update_temp

    put :update_result
    post :import_performance_collect
    get :index_all
  end

  resources :performance_attachments, path: 'attachments',
    only: [:create, :destroy] do
    collection do
      get :show
    end
  end

  resources :performance_alleges, path: 'alleges', only: [:create]
end

resources :performance_alleges, path: 'alleges', only: [:update, :show, :index] do
  member do
    post '/attachments', to: "performance_alleges#attachment_create"
    delete '/attachments/:attachment_id', to: "performance_alleges#attachment_destroy"
  end
end
