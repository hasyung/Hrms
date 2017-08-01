
get "/work_shifts/index", to: "work_shifts#index"  
put "/work_shifts/index/:id", to: "work_shifts#edit"  
post "/work_shifts/index", to: "work_shifts#create"  
get "/work_shifts/index/:id", to: "work_shifts#show"
post "/work_shifts/import", to: "work_shifts#import"
