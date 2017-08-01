resources :positions, except: :destroy do
  collection do
    post :batch_destroy
    post :adjust
    get  :export_to_xls, action: 'export_to_xls'
    get  :export_specification_pdf, action: 'export_specification_pdf'
  end
  member do
    get :employees
    get :formerleaders
  end

  resource :specification , only: [:create, :update, :show]
end

resources :position_changes, only: [:index, :show]

resources :position_records, only: [:index] do
  collection do
    get :export
  end
end

resources :position_change_records, only: [:create, :index, :destroy] do
  collection do
    post :batch_create
  end
end
