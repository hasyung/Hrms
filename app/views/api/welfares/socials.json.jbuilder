json.socials @socials do |social|
  json.location social['location']
  json.is_annual social['is_annual']
  json.pension social['pension']
  json.treatment social['treatment']
  json.unemploy social['unemploy']
  json.injury social['injury']
  json.illness social['illness']
  json.fertility social['fertility']
end