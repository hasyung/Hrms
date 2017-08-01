FactoryGirl.define do
	factory :gender_male, :class => 'CodeTable::Gender' do
		name "male"
		display_name "男"
	end

	factory :gender_femal, :class => 'CodeTable::Gender' do
		name "female"
		display_name "女"
	end
end