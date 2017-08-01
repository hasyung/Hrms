FactoryGirl.define do
  factory :night_record do
    no 1
    employee_no "003740"
    first_department {Faker::Name.name}
    shifts_type "三班倒"
    location "北京"
    night_number 2
    notes ""
    subsidy 10
  end

end
