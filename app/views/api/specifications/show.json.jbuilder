if @specification
  json.specification do
    json.id @specification.id
    json.duty @specification.duty
    json.personnel_permission @specification.personnel_permission
    json.financial_permission @specification.financial_permission
    json.business_permission @specification.business_permission
    json.superior @specification.superior
    json.underling @specification.underling
    json.internal_relation @specification.internal_relation
    json.external_relation @specification.external_relation
    json.qualification @specification.qualification
  end
end
