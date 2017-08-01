namespace :init do
  desc "初始化一部分员工和干部的年度和月度绩效数据"

  task performance: :environment do 
    year_date = Date.today.end_of_year
    month_date = Date.today.end_of_month

    Excel::PerformanceImporter.new("#{Rails.root}/public/annual_employee.xlsx", year_date, 'year').call
    Excel::PerformanceImporter.new("#{Rails.root}/public/annual_manager.xlsx", year_date, 'year').call
    Excel::PerformanceImporter.new("#{Rails.root}/public/employee_month.xlsx", month_date, 'month').call
  end

  desc "删除绩效中重复的数据"
  task fix_performance_repeat: :environment do
  	performances = []
    counts = 0
    performance_objs = Performance.where(assess_year: '2014')
    performances_count = performance_objs.size
    puts "总共需要处理#{performances_count}条数据"
  	Performance.where(assess_year: '2014').each do |performance|
  		if performances.include?([performance.employee_no,performance.assess_time])
  			performance.destroy
        counts += 1
  			next
  		end
  		performances << [performance.employee_no,performance.assess_time]
      counts += 1

      if counts%1000 == 0
        (counts.to_f/performances_count.to_f)*100
        puts "已处理#{((counts.to_f/performances_count.to_f)*100).to_i}%"
      end
  	end
  end
end