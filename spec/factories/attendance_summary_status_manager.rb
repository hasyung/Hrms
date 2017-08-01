FactoryGirl.define do 
  factory :attendance_summary_status_manager, :class => 'AttendanceSummaryStatusManager' do 
    summary_date "#{Date.today.strftime('%Y-%m')}"
  end
end