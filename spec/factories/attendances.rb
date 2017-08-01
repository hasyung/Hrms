FactoryGirl.define do
  factory :attendance do
    record_type "迟到"
    record_date Time.new.to_date
  end
end
