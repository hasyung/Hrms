require 'sidekiq/web'
require 'crono/web'

# 加载routes文件夹下面的路由文件
class ActionDispatch::Routing::Mapper
  def draw(routes_name)
    instance_eval(File.read(Rails.root.join("config/routes/#{routes_name}.rb")))
  end
end

Rails.application.routes.draw do
  # get 'work_shifts/index'

  mount Sidekiq::Web => '/sidekiq'
  mount Crono::Web => '/crontask'

  root "home#index"
  get "metadata", to: 'home#metadata'

  resources :sessions do
    collection do
      get :singpoint
    end
  end

  # 角色首页
  resources :roles

  get 'sign_in', to: 'sessions#new'
  delete 'sign_out', to: 'sessions#destroy'

  namespace :api, defaults: {format: :json} do
    get 'permissions', to: 'permissions#index'

    draw :department
    draw :position
    draw :employee
    draw :me
    draw :workflow
    draw :contract
    draw :attendance
    draw :vacation
    draw :performance
    draw :welfare
    draw :social
    draw :attendance_summary
    draw :annuity
    draw :salary
    draw :calc_step
    draw :birth_allowance
    draw :dinner_person_setup
    draw :dinner_fee
    draw :dinner_settle
    draw :dinner_change
    draw :night_fee
    draw :statement
    draw :fav_note
    draw :report
    draw :work_shift
    draw :title_info_change_record

    resources :search_conditions, only: [:index, :create, :destroy]

    get 'enum', to: 'enum#index'
    get 'sort', to: 'sort#index'

    resources :attachments, only: [] do
      collection do
        post :upload_xls
        post :upload_doc
        post :upload_image
        post :upload_file
        post :report_upload_file
      end
    end

    # 暂时绩效考核url
    get 'stat', to: "stat#index"

    namespace :external_api, path: '' do
      resources :external_applications, only: [] do
        collection do
          get :execute
          get :push
          post :receive
        end
      end
    end
  end

  namespace :admin do
    root :to => "home#index"

    get 'sign_in', to: 'sessions#new'
    delete 'sign_out', to: 'sessions#destroy'

    get 'run_async_task', to: 'home#run_async_task'

    resources :permissions do
      collection do
        get :permission_assign
        get :file_clerk_assign
        get :positions_select
        get :flow_relation_assign
        get :flow_relations_show
        get :role_menus

        post :destroy_file_clerk
        post :grant_permission
        post :confirm_file_clerk
        post :confirm_flow_relation
        post :create_role_menu

        put :edit_role_menu
      end
    end

    resources :backups, only: [:index] do
      collection do
        get :download
      end
    end

    resources :logs, only: [:show, :index]
    resources :holidays, only: [:index, :new, :create, :destroy]
    resources :external_applications do
      member do
        get :debug
        post :calc_signature
        get :send_push
      end
    end
    resources :change_records, only: [:index] do
      get :failed, on: :collection
      get :export, on: :collection
      get :send_again, on: :member
    end

  end

end
