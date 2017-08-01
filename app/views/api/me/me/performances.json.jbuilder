json.partial! 'api/performances/list'

json.meta do
  json.expire_day @expire_day.beginning_of_day
end
