# 为了前端统一接口，根据查询字符串来分发路由
get '/departments', to: "history/departments#index", constraints: lambda { |req| req.query_string.match(/(version)/) }
get '/departments/:department_id/positions', to: "history/positions#index", constraints: lambda { |req| req.query_string.match(/(version)/) }
get '/positions/:id/formerleaders', to: "history/positions#formerleaders", constraints: lambda { |req| req.query_string.match(/(version)/) }
get '/positions/:position_id/employees', to: "history/employees#index", constraints: lambda { |req| req.query_string.match(/(version)/) }
get '/departments/export_to_xls', to: "history/departments#export_to_xls", constraints: lambda { |req| req.query_string.match(/(version)/)}

shallow do
  resources :departments do
    collection do
      post :active
      post :revert
      get :addtional
      get :change_logs
      get :export_to_xls
      get :rewards
      put :reward_update
      post :update_set_book_no
    end

    resources :positions, only: [:index, :create]

    post :transfer
  end
end
