require 'rubygems'
require 'json'
namespace :init do 
	desc "生成2017年假期"
	task import_holiday_2017: :environment do
		holidays = JSON.parse('{"201701":{"01":"2","02":"1","07":"1","08":"1","14":"1","15":"1","21":"1","27":"2","28":"2","29":"2","30":"1","31":"1"},"201702":{"01":"1","02":"1","05":"1","11":"1","12":"1","18":"1","19":"1","25":"1","26":"1"},"201703":{"04":"1","05":"1","11":"1","12":"1","18":"1","19":"1","25":"1","26":"1"},"201704":{"02":"1","03":"1","04":"2","08":"1","09":"1","15":"1","16":"1","22":"1","23":"1","29":"1","30":"1"},"201705":{"01":"2","06":"1","07":"1","13":"1","14":"1","20":"1","21":"1","28":"1","29":"1","30":"2"},"201706":{"03":"1","04":"1","10":"1","11":"1","17":"1","18":"1","24":"1","25":"1"},"201707":{"01":"1","02":"1","08":"1","09":"1","15":"1","16":"1","22":"1","23":"1","29":"1","30":"1"},"201708":{"05":"1","06":"1","12":"1","13":"1","19":"1","20":"1","26":"1","27":"1"},"201709":{"02":"1","03":"1","09":"1","10":"1","16":"1","17":"1","23":"1","24":"1"},"201710":{"01":"2","02":"1","03":"1","04":"2","05":"1","06":"1","07":"1","08":"1","14":"1","15":"1","21":"1","22":"1","28":"1","29":"1"},"201711":{"04":"1","05":"1","11":"1","12":"1","18":"1","19":"1","25":"1","26":"1"},"201712":{"02":"1","03":"1","09":"1","10":"1","16":"1","17":"1","23":"1","24":"1","30":"1","31":"1"}}')
		
		
		holidays.each do |month, days|
			days.each do |day, flag|
				date = (month+day).to_date
				Holiday.create(record_date:date, flag:flag)
			end
		end
	end
end