FactoryGirl.define do
  factory :contract do
    department_name '保卫处'
    position_name '副处长'
    employee_name '何章林'
    apply_type '合同制'
    change_flag '新签'
    contract_no '000325'
    employee_no '000325'
    due_time 0
    start_date '2010-01-01'
    join_date '2010-01-01'
    status '在职'
    employee_exists 1
    employee_id 1

    factory :contract_l do
      department_name '保卫处'
      position_name '副处长'
      employee_name '李林'
      apply_type '合同制'
      change_flag '续签'
      contract_no 000335
      employee_no 000335
      due_time 4
      start_date '2011-01-01'
      end_date '2015-01-01'
      join_date '2010-01-01'
      status '在职'
      employee_exists 1
    end

    factory :contract_h do
      department_name '人力资源部'
      position_name '部长'
      employee_name '黄林'
      apply_type '合同制'
      change_flag '续签'
      contract_no 000435
      employee_no 000435
      due_time 0
      start_date '2011-01-01'
      join_date '1990-01-01'
      status '退休'
      employee_exists 0
      notes 'Just a test'
    end
  end
end
