FactoryGirl.define do
	factory :department_nature, :class => 'CodeTable::DepartmentNature' do
		name {Faker::Name.name}
	end
end