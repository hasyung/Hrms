get '/welfares/:category', to: "welfares#show"
resources :welfares, only: [] do
  post :update_socials, on: :collection
  post :update_dinners, on: :collection
end

resources :welfare_fees, only: [:index] do
  collection do
	  post :import
    get  :export
    get  :import_budget
    get  :getcategory_with_year
	end
end