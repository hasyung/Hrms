FactoryGirl.define do
  factory :category, :class => 'CodeTable::Category' do
    name {Faker::Name.name}
  end

  factory :master_pos_category, :class => 'CodeTable::Category' do
    name "主职"
  end
end
