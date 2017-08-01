FactoryGirl.define do
  factory :change_record_web do
    change_type "MyString"
event_time "2016-10-20"
is_pushed false
change_data "MyText"
ok_array "MyText"
failed_array "MyText"
  end

end
