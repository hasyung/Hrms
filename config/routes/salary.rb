resources :performance_salaries, only: [:index, :update] do
  collection do
    get :compute
    post :import
    get :export_base_salary
    get :export_nc
    get :export_approval
    get :export_point_base_salary
  end
end

resources :salaries, only: [:index] do
  collection do
    get :global
    post :update_global

    get :performance
    post :update_performance

    get :hours_fee
    post :update_hours_fee

    get :allowance
    post :update_allowance

    get :land_allowance
    post :update_land_allowance

    get :temp
    post :update_temp

    get :cold_subsidy
    post :update_cold_subsidy

    get :metadata

    get :temperature_amount
    put :update_temperature_amount
    get :communicate_allowance
    put :update_communicate_allowance
    get :position_cold_subsidy
    put :set_position_cold_subsidy
    get :communicate_of_duty_rank
    get :official_car_of_duty_rank
    put :set_communicate_of_duty_rank
    put :set_official_car_of_duty_rank
  end
end

put 'salaries/:category', to: "salaries#update"

resources :salary_person_setups do
  collection do
    post :upload_salary_set_book # 上传帐套
    post :upload_share_fund      # 上传公积金
    get :check_person_upgrade    # 检测调整档级
    get :export_to_xls

    post :import_hours_fee_setup
  end
end

resources :set_books, only: [:create, :update] do
  collection do
    get :info
    get :export_change_record
  end
end

get 'salary_person_setups/lookup', to: "salary_person_setups#show"

resources :basic_salaries, only: [:index, :update] do
  get :compute, on: :collection
  get :export_nc, on: :collection
  get :export_approval, on: :collection
end

resources :keep_salaries, only: [:index, :update] do
  get :compute, on: :collection
  get :export_nc, on: :collection
  get :export_approval, on: :collection
end

resources :allowances, only: [:index, :update] do
  collection do
    get :compute
    post :import
    get :export_nc
    get :export_communication_nc
    get :export_temp
    get :export_land_present
    get :export_car_present
    get :export_permit_entry
    get :export_security_check
    get :export_fly_honor
    get :export_communication
    get :export_resettlement
    get :export_group_leader
  end
end

resources :hours_fees, only: [:index, :update] do
  collection do
    get :compute
    post :import
    post :import_add_garnishee
    post :import_refund_fee
    get :export_nc
    get :export_approval
  end
end

resources :land_allowances, only: [:index, :update] do
  collection do
    get :compute
    post :import
    get :export_nc
    get :export_approval
  end
end

resources :rewards, only: [:index, :update] do
  collection do
    get :compute
    post :import
    get :export_nc
    get :export_approval
  end
end

resources :transport_fees, only: [:index, :update] do
  collection do
    get :compute
    get :export_nc
    get :export_approval
  end
end

resources :airline_fees, only: [:index, :update] do
  collection do
    get :export
    get :compute_oversea_food_fee
  end
end

resources :salary_overviews, only: [:index, :update] do
  collection do
    get :compute
    get :export_nc
    get :export_approval
  end
end

resources :salary_changes, only: [:index, :show, :update]
resources :salary_grade_changes, only: [:index, :update, :show]

resources :birth_salaries, only: [:index] do
  collection do
    get :compute
  end
end

resources :bus_fees, only: [:index, :update] do
  collection do
    post :import
    get  :compute
  end
end

resources :official_cars, only: [:index, :update] do
  collection do
    get  :compute
  end
end

resources :security_fees, only: [:index, :update]

resources :salary_position_relations, only: [:index, :update]
