resources :annuities, only: [:index, :update, :show] do
  collection do
    get :export_to_xls
    get :export_annuity_to_xls
    get :show_cardinality
    get :cal_year_annuity_cardinality
    get :cal_annuity
    get :list_annuity
  end
end

resources :annuity_apply, only: [:index] do
  collection do
    get :apply_for_annuity
    get :handle_apply
  end
end
