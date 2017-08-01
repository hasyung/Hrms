FactoryGirl.define do
  factory :social_change_info do
    category '属地变化'
    location_was '重庆'

    factory :log_first, :class => 'SocialChangeInfo' do
    end
  end

end
