namespace :vacation_record do
	desc "增加年假初始化天数"
	task init_annual_days: :environment do
		last_year = 2015#Time.new.last_year.year
    current_year = 2016#Time.new.year
    current_date = "2016-07-01".to_date#Time.new.to_date

    count = 0

    

    #1月1日/7月1日更新年假
    #1月/7月1日扣减上年度的年假，正数扣减成0，负数需要和本年度年假合并
    ActiveRecord::Base.transaction do
      
      start_date = Time.parse("#{last_year}-1-1 00:00:00")
      end_date = Time.parse("#{last_year}-6-30 24:00:00")


      #update_over_year_days(current_year)

      Employee.where("join_scal_date < ?", "#{current_year.to_i - 1}-1-1").find_in_batches do |collection|
	      collection.each do |employee|
	        record = VacationRecord.find_or_initialize_by({employee_id: employee.id, year: current_year})
	        record.init_days = VacationRecord.get_year_days(employee)
	        record.save
	      end
	    end




      # update_less_year_days(start_date, end_date, current_year)
      Employee.where(join_scal_date: start_date..end_date).find_in_batches do |collection|
	      collection.each do |employee|
	        record = VacationRecord.find_or_initialize_by({employee_id: employee.id, year: current_year})
	        record.init_days = VacationRecord.get_year_days(employee)
	        record.save
	      end
	    end
      
      
    
      start_date = Time.parse("#{last_year}-7-1 00:00:00")
      end_date = Time.parse("#{last_year}-12-31 24:00:00")
      
       Employee.where(join_scal_date: start_date..end_date).find_in_batches do |collection|
	      collection.each do |employee|
	        record = VacationRecord.find_or_initialize_by({employee_id: employee.id, year: current_year})
	        record.init_days = VacationRecord.get_year_days(employee)
	        record.save
	      end
	    end

    end

	end
end