json.id social.id
json.employee_id social.employee_id
json.employee_no social.employee_no
json.employee_name social.employee_name
json.department_name social.department_name
json.position_name social.position_name
json.social_location social.social_location
json.social_account social.social_account

json.pension_cardinality social.pension_cardinality.try(:to_f)
json.other_cardinality social.treatment_cardinality.try(:to_f)
json.temp_cardinality social.temp_cardinality.try(:to_f)

json.pension social.pension
json.treatment social.treatment
json.unemploy social.unemploy
json.injury social.injury
json.illness social.illness
json.fertility social.fertility