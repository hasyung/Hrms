# 验证逻辑：
# 一、干部(category: 领导和干部)分配：
# 1. 干部对应的分配总额(部门分配结果总和) <= 干部核定额度
# 2. 干部对应的留存分配总额（部门留存总和）<= 干部留存（上月）额度
# 二、人员（干部 + 员工）分配：
# 1. 当月分配总和 <= 人员当月分配额度
# 2. 留存分配总和 <= 部门留存总额(上月)
# 三、如果该部门是该员工的第二绩效部门，那么不参与上诉验证
##### 
# 留存持久化：
# 包括干部留存，员工留存，总留存


module Excel
  class MonthPerformanceImporter < PerformanceImporterBase
    attr_reader :warning_message
    
    def initialize(file, assess_time, category, department_id)
      @assess_time = assess_time.to_date
      @month = @assess_time.strftime("%Y-%m")
      @category = category
      @assess_year = @assess_time.year.to_s
      @attributes = []

      @department = nil
      @department_id = department_id
      
      @checking_attributes = [] # 用于做验证的属性值
      @leader_attributes = [] # 用于做验证的属性值
      
      @leader_distribute_amount = nil 
      @leader_reserved_amount = nil
      @department_distribute_amount = nil 
      @department_reserved_amount = nil
      
      @last_department_salary = nil 
      @department_salary = nil

      @warning_message = []

      super(file, 1)
    end

    def call
      ActiveRecord::Base.transaction do 
        @attributes.each do |attribute|
          employee = attribute[:employee]
          performance = employee.performances.find_by(assess_time: attribute[:assess_time], department_id: @department.id)
          performance_salary = employee.performance_salaries.find_by(month: @month)

          if performance
            performance.update!(attribute.except(:employee))
          else
            Performance.create!(attribute.except(:employee))
          end

          performances = employee.performances.where(assess_time: @assess_time)
          if performances.count == 1
            @perfor = performances.first
          else
            first_performance = performances.first
            second_performance = performances.last 
            if (first_performance.department_distribute_result.to_f + first_performance.department_reserved.to_f) > (second_performance.department_distribute_result.to_f + second_performance.department_reserved.to_f)
              @perfor = first_performance
            elsif (first_performance.department_distribute_result.to_f + first_performance.department_reserved.to_f) > (second_performance.department_distribute_result.to_f + second_performance.department_reserved.to_f)
              @perfor = second_performance
            else
              @perfor = performances.find_by(department_name: employee.department.full_name)
            end
          end

          performance_salary.update!(department_reserved: @perfor.department_reserved.to_f, department_distribute: @perfor.department_distribute_result.to_f, result: @perfor.result)
        end

        global = ::Salary.find_by(category: 'global').form_data["coefficient"][@month]
        global ||= {}
        first_department = @department.full_name.split("-")[0]
        if %w(文化传媒广告公司 校修中心).include?(first_department)
          @rate = 1
        elsif first_department == '商务委员会'
          @rate = global["business_council"].to_f
        elsif first_department == '物流部'
          @rate = global["logistics"].to_f
        else
          @rate = global["perf_execute"].to_f
        end
            
        remain = @last_department_salary.try(:remain).to_f + @department_salary.try(:verify_limit).to_f - @department_distribute_amount.to_f - @department_reserved_amount.to_f
        leader_remain = @last_department_salary.try(:leader_remain).to_f + @department_salary.try(:leader_verify_limit).to_f - @leader_distribute_amount.to_f - @leader_reserved_amount.to_f
        employee_remain = remain - leader_remain
        @department_salary.update!(remain: (remain*@rate).round(2), leader_remain: (leader_remain*@rate).round(2), employee_remain: (employee_remain*@rate).round(2))
      end
    end

    def parse
      (1..@last_row).each do |index|
        @current_row_data = @data.row(index)
        attribute = get_attribute
        
        next if attribute.empty?

        @attributes << attribute
        if attribute[:employee].department.full_name == attribute[:department_name]
          @checking_attributes << attribute
          if attribute[:employee].category.display_name != "员工"
            @leader_attributes << attribute
          end
        end
      end

      self
    end

    def valid?
      # 1. 判断在读取数据的时候是否存在错误
      # 2. 判断领导的部门分配不大于上月部门留存，判断总分配不大于上月总留存
      return false if @errors.count != 0
      init_data
      return true if department_distribute_valid?
      return false
    end

    private
    def init_data
      @last_department_salary = @department.department_salaries.find_by(month: @assess_time.advance(months: -1).strftime("%Y-%m"))
      @department_salary = @department.department_salaries.find_by(month: @assess_time.strftime("%Y-%m"))
      @performances = Performance.where(assess_time: @assess_time, department_id: @department.id)

      leader_ids = @performances.where(is_leader: true).map(&:employee_id) - @leader_attributes.map{|attribute| attribute[:employee_id]} 
      leader_performances = @performances.where(employee_id: leader_ids)
      employee_ids = @performances.map(&:employee_id) - @checking_attributes.map{|attribute| attribute[:employee_id]}
      employee_performances = @performances.where(employee_id: employee_ids)
      
      @leader_reserved_amount = @leader_attributes.inject(0){|result, attribute| result += attribute[:department_reserved].to_f} + leader_performances.map(&:department_reserved).map(&:to_f).inject(&:+).to_f
      @leader_distribute_amount = @leader_attributes.inject(0){|result, attribute| result += attribute[:department_distribute_result].to_f} + leader_performances.map(&:department_distribute_result).map(&:to_f).inject(&:+).to_f
      @department_distribute_amount = @checking_attributes.inject(0){|result, attribute| result += attribute[:department_distribute_result].to_f} + employee_performances.map(&:department_distribute_result).map(&:to_f).inject(&:+).to_f
      @department_reserved_amount = @checking_attributes.inject(0){|result, attribute| result += attribute[:department_reserved].to_f} + employee_performances.map(&:department_reserved).map(&:to_f).inject(&:+).to_f
    end

    def get_attribute
      performace_attr = performace_attributes

      # 这里存在顺序依赖，不好！！！
      @errors << @error_message and return {} unless attributes_valid?
      @errors << @error_message and return {} unless month_base_valid?(performace_attr)
      @errors << @error_message and return {} unless department_valid?

      {assess_time: @assess_time, category: @category, assess_year: @assess_year}.merge(employee_attributes).merge(performace_attr)
    end

    def department_valid?
      @department = Department.find_by(id: @department_id)
      personal_salary_setup = @employee.salary_person_setup

      unless @department
        @error_message << "主机构#{@data.row(1)[1]}不存在，请检查是否填写错误"
        return false
      end

      # 检测双部门考核，若有判断主部门或副部门是否一致
      unless [@employee.department.parent_chain.first.id, personal_salary_setup.second_department_id].include?(@department.id)
        department_ids = Department.get_self_and_childrens([@department.id])
        is_jiediao = @employee.special_states.where("special_states.special_category = '借调' and 
        special_states.department_id in (?) and (special_states.special_date_from <= 
        '#{@assess_time.beginning_of_month.advance(days: +14)}' and (special_states.special_date_to is null or 
        special_states.special_date_to >= '#{@assess_time.end_of_month}') or (special_states.special_date_from <= 
        '#{@assess_time.beginning_of_month}' and special_states.special_date_to >= 
        '#{@assess_time.beginning_of_month.advance(days: +14)}'))", department_ids).blank?
        if is_jiediao
          @error_message << "人员#{@employee.name}的绩效考核机构不存在#{@department.name}; " 
          return false
        end
      end

      return true
    end

    def employee_attributes
      import_department_name = [@current_row_data[1], @current_row_data[2], @current_row_data[3]].compact.join("-")
      employee_department_name = @employee.department.full_name
      is_leader = (@employee.category.display_name == "员工" ? false : true)

      if import_department_name == employee_department_name
        full_name = employee_department_name
        position_name = @employee.master_position.name
      else
        full_name = import_department_name
        position_name = nil
      end


      {
        employee: @employee,
        employee_id: @employee.id,
        employee_name: @employee.name,
        employee_no: @employee.employee_no,
        department_name: full_name,
        position_name: position_name,
        channel: @employee.channel.try(:display_name),
        employee_category: @employee.pcategory,
        department_id: @department.id,
        is_leader: is_leader
      }
    end

    def month_base_valid?(performace_attr)
      return true unless performace_attr[:result] # 当没有打绩效，视为无效，让验证通过
      return true if performace_attr[:month_distribute_base] == 0
      
      month_distribute_scal = (performace_attr[:department_distribute_result].to_f + performace_attr[:department_reserved].to_f) / performace_attr[:month_distribute_base].to_f
      scal = {'优秀' => (1.2..1.5), '良好' => (1.1..1.2), '合格' => (0.7..1), '待改进' => (0..0.5), '不合格' => [0]}[performace_attr[:result]]

      @warning_message << "#{@employee.name}的绩效考核结果数据错误" unless scal
      @warning_message << "#{@employee.name}的绩效薪酬总额与绩效等级不符" if scal && scal.exclude?(month_distribute_scal)
      return true
    end

    def department_distribute_valid?
      @errors << "干部留存总额不能大于上月干部留存总额" if @leader_reserved_amount > @last_department_salary.try(:leader_remain).to_f
      @errors << "干部当月分配总额不能大于干部核定额度" if @leader_distribute_amount > @department_salary.try(:leader_verify_limit).to_f
      @errors << "干部和员工的当月分配总额不能大于总核定额度" if @department_distribute_amount > @department_salary.try(:verify_limit).to_f
      @errors << "干部和员工的留存分配总额不能大于部门留存总额" if @department_reserved_amount > @last_department_salary.try(:remain).to_f

      @errors.count > 0 ? false : true
    end

    def performace_attributes
      (headers.except(:employee_no, :employee_name, :department_name)).inject({}) do |attributes, (attr_name, value)|
        attributes[attr_name] = @current_row_data[value[:col_index]]
        attributes
      end
    end

    def headers
      {
        employee_no: {
          col_index: 0,
          type: String,
          msg: '员工编号必须为文本类型; ',
          presence: true
        },
        employee_name: {
          col_index: 5,
          type: String,
          msg: '员工姓名必须为文本类型; ',
          presence: true
        },
        month_distribute_base: {
          col_index: 7,
          type: Float,
          msg: '月度分配基数必须为数字类型; ',
          presence: true
        },
        result: {
          col_index: 8,
          type: String,
          msg: '考核结果必须为文本类型; ',
          presence: false
        },
        department_distribute_result: {
          col_index: 9,
          type: Float,
          msg: '部门当月分配结果必须为数字类型; ',
          presence: false
        },
        department_reserved: {
          col_index: 10,
          type: Float,
          msg: '部门留存分配结果必须为数字类型; ',
          presence: false
        }
      }
    end
  end
end