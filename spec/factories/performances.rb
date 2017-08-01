FactoryGirl.define do
  factory :performance do
    employee_name {Faker::Name.name}
    employee_no {Faker::Number.number(6)}
    department_name '人力资源部-人事调配室'
    position_name '人事专员'
    channel '员工'
    assess_time {Faker::Date.between(100.days.ago, Date.today)}
    assess_year {Faker::Date.between(100.days.ago, Date.today).year}
    result '合格'

    factory :manager_perfor do
      employee_name '王麻子'
      employee_no '666666'
      department_name '人力资源部-人事调配室'
      position_name '主官'
      channel '管理'
      assess_time '2015'
      result '合格'
    end
  end
end
