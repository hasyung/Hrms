get '/workflows/:flow_type/record', to: "workflows#record"
get '/workflows/:flow_type/record/:id', to: 'workflows#single_record'
post '/workflows/:flow_type', to: "workflows#create"
post 'workflows/:flow_type/proxy_for_leave', to: "workflows#proxy_for_leave"
post '/workflows/:flow_type/batch_create', to: "workflows#batch_create"
put '/workflows/:flow_type/:id/supplement', to: "workflows#supplement"
put '/workflows/:flow_type/:id/transfer_to_occupation_injury', to: 'workflows#transfer_to_occupation_injury'
put '/workflows/:flow_type/:id/repeal', to: "workflows#repeal"
put '/workflows/:flow_type/:id/deduct', to: "workflows#deduct"
post '/workflows/:flow_type/attachments', to: "workflows#attachments"
post '/workflows/:flow_type/:id/flow_nodes', to: "workflows#node_create"
put '/workflows/:flow_type/:id/flow_nodes/:node_id', to: "workflows#node_update"
put '/workflows/:flow_type/:id/change', to: "workflows#change"
put '/workflows/:flow_type/:id', to: "workflows#update"
get '/workflows/:flow_type/:id', to: "workflows#show"
get '/workflows/:flow_type', to: "workflows#index"
put '/workflows/:flow_type/record/:id', to: 'workflows#adjust_leave_type'
get '/workflows', to: "workflows#index"
post '/workflows/instead_leave/instead_leave', to: 'workflows#instead_leave'

post '/me/todos/:id/flow_nodes', to: 'workflows#node_create'
put  '/me/todos/:id/flow_nodes/:node_id', to: 'workflows#node_update'

# 客舱特殊考勤接口
get '/workflows/vacation/distribute/vacation_distribute_list', to: 'workflows#vacation_distribute_list'
post '/workflows/vacation/cabin_vacation_import', to: 'workflows#cabin_vacation_import'
put '/workflows/approve_vacation_list', to: 'workflows#approve_vacation_list'
