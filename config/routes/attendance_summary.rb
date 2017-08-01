resources :attendance_summaries, only: [:index, :update, :show] do
  collection do
    put :department_hr_confirm # 部门HR专员汇总确认
    put :department_leader_check # 部门领导汇总审核
    put :hr_leader_check # HR部门领导审核
    put :hr_labor_relation_member_check # HR劳动关系管理员审核
    get :check_list # 考勤汇总审核列表
    put :administrator_check # 管理员审核确认
    get :attendance_summary_department_list # 汇总审核里面所有部门名称列表

    get :export_xls
    post :import
  end
end

get '/attendance_summaries/check_list/:id', to: "attendance_summaries#show"
put '/attendance_summaries/check_list/:id', to: "attendance_summaries#update"
