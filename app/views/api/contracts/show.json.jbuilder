json.contract do
  json.id                @contract.id
  json.employee_id       @contract.employee_id
  json.contract_no       @contract.contract_no
  json.employee_no       @contract.employee_no
  json.employee_name     @contract.employee_name
  json.department_name   @contract.department_name
  json.position_name     @contract.position_name
  json.apply_type        @contract.apply_type
  json.change_flag       @contract.change_flag
  json.start_date        @contract.start_date
  json.end_date          @contract.end_date
  json.end_date_str      @contract.end_date || '无固定'
  json.is_unfix          @contract.is_unfix
  json.due_time          @contract.due_time
  json.join_date         @contract.join_date
  json.status            @contract.status
  json.employee_exists   @contract.employee_exists
  json.notes             @contract.notes
end
