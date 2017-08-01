json.rewards @rewards do |reward|
  json.partial! 'api/rewards/reward', salary: reward
  json.category "reward"
end

json.partial! 'shared/page_basic'
