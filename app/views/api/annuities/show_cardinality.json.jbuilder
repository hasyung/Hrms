json.social_records @records do |record|
  json.month record.compute_month
  json.pension_cardinality record.pension_cardinality
end

json.meta do
  json.annuity_cardinality @cardinality
end
