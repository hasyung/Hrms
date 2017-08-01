json.calc_step do
  json.id @calc_step.id
  json.employee_id @calc_step.employee_id
  json.category @calc_step.category
  json.step_notes @calc_step.step_notes
  json.amount format("%.2f" , @calc_step.amount || 0)
  json.created_at @calc_step.created_at
end