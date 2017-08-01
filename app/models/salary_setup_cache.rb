class SalarySetupCache < ActiveRecord::Base
	serialize :data, Hash

	belongs_to :employee
	belongs_to :salary_change

	attr_accessor :prev_channel, :channel

	CHANNEL_LEVEL = %w(服务B 服务C 管理/营销 航务航材 信息 机务)
	CHANNEL_FULL_NAME = %w(服务B 服务C-驾驶 服务C-3 服务C-2 服务C-1 管理 营销 航务航材 信息 机务)

	PERFORMANCE = {
		'服务C-1' => 'service_c_1_perf',
		'服务C-2' => 'service_c_2_perf',
		'服务C-3' => 'service_c_3_perf',
		'服务C-驾驶' => 'service_c_driving_perf',
		'管理' => 'manage_market_perf',
		'营销' => 'manage_market_perf',
		'航务航材' => 'airline_business_perf',
		'信息' => 'information_perf',
		'机务' => 'service_normal_perf',
	}

	PERFORMANCE_RESULT = {
		'优秀' => 'A',
		'良好' => 'B',
		'合格' => 'C',
		'随动' => 'D',
	}

	def change_data
		self.prev_channel = CodeTable::Channel.find_by(id: self.prev_channel_id).try(:display_name)
		self.channel = CodeTable::Channel.find_by(id: self.channel_id).try(:display_name)

		cache_hash = []

		perf_salary = Salary.find_by(category: PERFORMANCE[self.channel])
		minimum_wage = Salary.find_by(category: 'global').form_data["minimum_wage"].round(2)
		salary_person_setup = self.employee.salary_person_setup

		last_year = self.salary_change.change_date.last_year.year
		performance = self.employee.performances.find_by(category: 'year', assess_year: last_year.to_s)
		result = performance.present? ? performance.try(:result) : '合格'
		
		if self.channel == '服务B'
			# salary_person_setup.base_money = minimum_wage
			# salary_person_setup.performance_money -= minimum_wage if salary_person_setup.performance_money.to_f >= minimum_wage
		else
			change_performance(perf_salary, salary_person_setup, result, get_up_or_down?)
			cache_hash |= ['performance_wage', 'performance_flag', 'performance_money']
		end

		self.data = salary_person_setup.attributes.select{|k, v| cache_hash.include?(k)}
	end

	def get_up_or_down?
		prev_index, index = 0, 0

		CHANNEL_LEVEL.each do |c|
			prev_index = CHANNEL_LEVEL.index(c) if c.include?(self.prev_channel.split('-').first)
			index = CHANNEL_LEVEL.index(c) if c.include?(self.channel.split('-').first)
		end
		if prev_index > index
			return false                   ### down
		else
			return true                    ### up
		end
	end

	def change_performance(perf_salary, salary_person_setup, result, is_up)
		if salary_person_setup.performance_money.to_f > 0 && self.prev_channel != '服务B'
			@flag, @amount = perf_salary.get_flag_and_amount(PERFORMANCE_RESULT[result], salary_person_setup.performance_money, is_up)
		else
			diff_year = salary_person_setup.employee.scal_working_years.to_i
			if diff_year >= 2
				@amount = perf_salary.get_amount_by_column(PERFORMANCE_RESULT[result], diff_year)
			else
				diff_year = (Date.difference_in_months(self.salary_change.change_date, salary_person_setup.employee.join_scal_date)/12.0).round(2)
				@amount = perf_salary.get_amount_by_column(PERFORMANCE_RESULT['随动'], diff_year)
			end
			@flag = perf_salary.get_flag_by_amount(@amount)
		end

		salary_person_setup.performance_wage = perf_salary.category
		salary_person_setup.performance_flag = @flag
		salary_person_setup.performance_money = @amount
	end
end
