json.id birth_allowance.id
json.employee_id birth_allowance.employee_id
json.employee_no birth_allowance.employee_no
json.employee_name birth_allowance.employee_name
json.department_name birth_allowance.department_name
json.position_name birth_allowance.position_name
json.sent_date birth_allowance.sent_date
json.sent_amount format("%.2f" , birth_allowance.sent_amount || 0)
json.deduct_amount format("%.2f" , birth_allowance.deduct_amount || 0)
