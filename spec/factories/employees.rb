FactoryGirl.define do
  factory :employee, class: "Employee" do
    name {Faker::Name.name}
    password {Faker::Internet.password}
    employee_no {Faker::Number.number(6)}
    identity_no {Faker::Number.number(18)}
    birth_place {Faker::Address.street_address}
    native_place {Faker::Address.street_address}
    school {Faker::Name.name}
    major {Faker::Name.name}
    birthday {60.years.ago}
    start_work_date  {40.years.ago}
    join_scal_date {20.years.ago}
    favicon Faker::Avatar.image(Faker::Name.name, "50x50", "jpg")
    favicon_type "image/jpeg"
    favicon_size 2000
    sort_no 0
    month_distribute_base {Faker::Number.number(5)}
    pcategory "员工"
    annuity_cardinality {Faker::Commerce.price}
    annuity_status true
    identity_name {Faker::Name.name}

    factory(:hr_labor_relation_member) do
      name "hr_labor_relation_member"
    end

    factory(:grade_1st_leader) do
      name "grade_1st_leader"
    end

    factory(:rear_service_member) do
      name "rear_service_member"
    end

    factory(:rear_service_leader) do
      name "rear_service_leader"
    end
  end
end
