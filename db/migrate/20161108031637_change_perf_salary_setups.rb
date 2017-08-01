class ChangePerfSalarySetups < ActiveRecord::Migration
  def change
  	Salary.transaction do
	  	salaries = Salary.where("category in (?)", %w(manage_market_perf 
	  		airline_business_perf information_perf service_normal_perf service_c_1_perf 
	  		service_c_2_perf service_c_3_perf service_c_driving_perf))

	  	salaries.each do |salary|
	  		form_data = salary.form_data
  			form_data["flag_list"] |= %w(P Q R S T)
  			form_data["flag_names"] = form_data["flag_names"].merge!({
  					"P" => "五星级",
  					"Q" => "四星级",
  					"R" => "三星级",
  					"S" => "二星级",
  					"T" => "一星级"
  				})

  			salary.update(form_data: form_data)
	  	end
	  end

  end
end
