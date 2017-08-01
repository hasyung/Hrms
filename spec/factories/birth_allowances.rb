FactoryGirl.define do
  factory :birth_allowance do
    employee_id 1
    employee_no "901112"
    employee_name "张三"
    department_name "人力资源部"
    position_name "总经理"
    sent_date "2015-10-22"
    sent_amount 10000
    deduct_amount 5000
  end
end
