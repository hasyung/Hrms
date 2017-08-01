FactoryGirl.define do
	factory :employment_status, :class => 'Employee::EmploymentStatus' do
		name {Faker::Name.name}	
		display_name "正式员工"
	end
end