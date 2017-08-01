class SocialRecord < ActiveRecord::Base
  belongs_to :employee

  default_scope {order('compute_date desc')}

  before_save do
    self.compute_date = self.compute_month + "-01" if compute_month_changed?
  end

  validates :compute_month, uniqueness: { scope: [:compute_month, :employee_id] }

  COLUMNS = %w(employee_id compute_month compute_date employee_name employee_no department_name
          identity_no social_account social_location pension_cardinality other_cardinality pension_company_scale
          pension_personage_scale pension_company_money pension_personage_money treatment_company_scale
          treatment_personage_scale treatment_company_money treatment_personage_money unemploy_company_scale
          unemploy_personage_scale unemploy_company_money unemploy_personage_money injury_company_scale
          injury_personage_scale injury_company_money injury_personage_money  illness_company_scale
          illness_personage_scale illness_company_money illness_personage_money fertility_company_scale
          fertility_personage_scale fertility_company_money fertility_personage_money t_company t_personage)

  class << self
    def check_compute(compute_month)
      #1. 检查社保全局设置是否完备
      socials = Welfare.find_by(category: 'socials')
      return  socials.check_socials if  socials.check_socials

      #2. 检查属地是否完备
      names = SocialPersonSetup.check_location.map(&:name)
      return check_error_messages(names, "以下员工属地为空") if names.present?

      #3. 检查年度基数是否完备
      names = SocialPersonSetup.check_cardinality.map(&:name)
      return check_error_messages(names, "以下#{Welfare.get_is_annual_locations.join('，')}的员工年度基数为空") if names.present?

      #4. 检查上月的薪酬数据是否已经导入
      import_date = Date.parse(compute_month + "-01").prev_month
      names = SocialCardinality.check_last_month(import_date).map(&:name)
      return check_error_messages(names, "以下非#{Welfare.get_is_annual_locations.join('，')}的员工上月薪酬数据没有导入") if names.present?
      nil
    end

    def check_error_messages(arr, title)
      message = title + "【"
      if(arr.size > 10)
        message += arr.first(10).join('，') + "】等#{arr.size}人"
      else
        message += arr.join('，') + "】"
      end
    end

    def compute(compute_month)
      SocialCardinality.transaction do
        #1. 计算上月基数
        import_date = Date.parse(compute_month + "-01").prev_month
        socials =  Welfare.find_by(category: 'socials').form_data
        SocialCardinality.compute_cardinality(socials, import_date)

        #2. 计算本月社保明细
        values = []

        SocialPersonSetup.joins(:employee).each do |personage|
          social = socials.select{|s|s['location'] == personage.social_location}.first

          cardinalities = compute_social(personage, import_date, social)
          # next if cardinalities.blank? or cardinalities[:pension_cardinality].blank?
          pension = compute_detail(social, cardinalities[:pension_cardinality], 'pension', personage.pension)
          treatment = compute_detail(social, cardinalities[:treatment_cardinality], 'treatment', personage.treatment)
          unemploy = compute_detail(social, cardinalities[:unemploy_cardinality], 'unemploy', personage.unemploy)
          injury = compute_detail(social, cardinalities[:injury_cardinality], 'injury', personage.injury)
          illness = compute_detail(social, cardinalities[:illness_cardinality], 'illness', personage.illness)
          fertility = compute_detail(social, cardinalities[:fertility_cardinality], 'fertility', personage.fertility)

          t_company = (pension[:company_money] + treatment[:company_money] + unemploy[:company_money] +
                       injury[:company_money] + illness[:company_money] + fertility[:company_money]).round(2)
          t_personage = (pension[:personage_money] + treatment[:personage_money] + unemploy[:personage_money] +
                         injury[:personage_money] + illness[:personage_money] + fertility[:personage_money]).round(2)

          values << [personage.employee.id, compute_month, compute_month + "-01",
                     personage.employee.name, personage.employee.employee_no,
                     personage.employee.department.full_name, personage.employee.identity_no,
                     personage.social_account, personage.social_location] + cardinalities.values.first(2) +
                     pension.values + treatment.values + unemploy.values + injury.values +
                     illness.values + fertility.values + [t_company, t_personage]
        end

        social_records = SocialRecord.where("compute_month = '#{compute_month}'")
        social_records.delete_all if social_records.present?
        SocialRecord.import(COLUMNS, values, validate: false)
        SocialPersonSetup.where("id in (?)", SocialPersonSetup.joins(employee: :social_records).group(
          "social_records.employee_id").having("count(social_records.employee_id) >= 2").where(
            "social_person_setups.temp_cardinality is not null").map(&:id)).update_all(temp_cardinality: nil)
      end
    end

    def show_record(employee, date)
      SocialRecord.unscoped do
        employee.social_records.where("compute_month like '#{date}%'").order("compute_month")
      end
    end

    # 实时计算(针对新加入的员工),逻辑规则为
    # 1. 首先取的员工去年的社保缴费记录, 如果记录够12条(全年缴满),那么使用去年的缴费记录计算年金基数
    # 2. 如果员工去年的社保缴费记录不足12条, 但是总的社保缴费记录够12条,那么取最近的12条记录计算年金基数
    # 3. 如果员工的社保缴费总数记录不足12条,那么取已有的社保缴费纪录计算年金基数
    def cal_annuity_cardinality(employee)
      SocialRecord.unscoped do
        last_year = Date.today.last_year.year
        last_year_records = employee.social_records.where("compute_month like '#{last_year}%'")
        last_year_records_count = employee.social_records.where("compute_month like '#{last_year}%'").count

        all_records = employee.social_records.order("compute_month")
        all_records_count = employee.social_records.order("compute_month").count

        if last_year_records_count == 12
          cardinality = last_year_records.sum(:pension_cardinality).to_f / 12

        elsif last_year_records_count < 12 and all_records_count >= 12
          cardinality = all_records.limit(12).sum(:pension_cardinality).to_f / 12

        elsif all_records_count < 12 and all_records_count > 0
          cardinality = all_records.sum(:pension_cardinality).to_f / all_records_count

        else
          cardinality = 0
        end

        cardinality.round
      end
    end

    # 年度计算
    # 针对全部在缴的员工一年一次计算员工年金基数
    # 去的员工去年的社保缴费记录,根据每个月社保个人缴纳的基数算取平均数为个人年度年金基数
    def cal_year_annuity_cardinality(employee, last_year)
      last_year_records = employee.social_records.where("compute_month like '#{last_year}%'")
      last_year_records_count = employee.social_records.where("compute_month like '#{last_year}%'").count
      cardinality = last_year_records_count == 0 ? 0 : last_year_records.sum(:pension_cardinality).to_f / last_year_records.size
      cardinality.round
    end

    private
    def compute_social(personage, import_date, social)
      pension_cardinality, treatment_cardinality, unemploy_cardinality = nil, nil, nil
      injury_cardinality, illness_cardinality, fertility_cardinality = nil, nil, nil

      if personage.temp_cardinality && personage.employee.social_records.size < 2
        pension_cardinality  = personage.temp_cardinality
        treatment_cardinality = personage.temp_cardinality
        unemploy_cardinality = personage.temp_cardinality
        injury_cardinality = personage.temp_cardinality
        illness_cardinality = personage.temp_cardinality
        fertility_cardinality = personage.temp_cardinality
      else
        if Welfare.get_is_annual_locations.include?(personage.social_location)
          pension_cardinality = get_annual_cardinality(personage.pension_cardinality, social["pension"])
          treatment_cardinality = get_annual_cardinality(personage.treatment_cardinality, social["treatment"])
          unemploy_cardinality = get_annual_cardinality(personage.unemploy_cardinality, social["unemploy"])
          injury_cardinality = get_annual_cardinality(personage.injury_cardinality, social["injury"])
          illness_cardinality = get_annual_cardinality(personage.illness_cardinality, social["illness"])
          fertility_cardinality = get_annual_cardinality(personage.fertility_cardinality, social["fertility"])
        else
          social_cardinality = personage.employee.social_cardinalities.find_by(import_date: import_date)
          # return if social_cardinality.blank?
          pension_cardinality = social_cardinality.pension_cardinality
          treatment_cardinality = social_cardinality.treatment_cardinality
          unemploy_cardinality = social_cardinality.unemploy_cardinality
          injury_cardinality = social_cardinality.injury_cardinality
          illness_cardinality = social_cardinality.illness_cardinality
          fertility_cardinality = social_cardinality.fertility_cardinality
        end
      end
      {
        pension_cardinality: pension_cardinality,
        treatment_cardinality: treatment_cardinality,
        unemploy_cardinality: unemploy_cardinality,
        injury_cardinality: injury_cardinality,
        illness_cardinality: illness_cardinality,
        fertility_cardinality: fertility_cardinality
      }
    end

    def compute_detail(social, cardinality, type, is_buy)
      company_scale, personage_scale, company_money, personage_money  = 0, 0, 0, 0
      if is_buy
        if social["#{type}"]["is_ration"]
          company_money = social["#{type}"]["company_money"].to_f.round(2)
          personage_money = social["#{type}"]["personage_money"].to_f.round(2)
        else
          company_scale = social["#{type}"]["company_percent"].to_f/100.0
          personage_scale = social["#{type}"]["personage_percent"].to_f/100.0
          company_money = ((social["#{type}"]["company_percent"].to_f/100.0)*cardinality).try(:round, 2)
          personage_money = ((social["#{type}"]["personage_percent"].to_f/100.0)*cardinality).try(:round, 2)
        end
      end
      {
        company_scale: company_scale,
        personage_scale: personage_scale,
        company_money: company_money,
        personage_money: personage_money
      }
    end

    def get_annual_cardinality(cardinality, social)
      social["upper_limit"] ||= 0
      social["lower_limit"] ||= 0
      cardinality ||= 0
      if((social["upper_limit"] == 0 && social["lower_limit"] == 0) || cardinality == 0)
        return 0
      elsif cardinality > social["upper_limit"]
        return social["upper_limit"]
      elsif cardinality < social["lower_limit"]
        return social["lower_limit"]
      else
        return cardinality
      end
    end

  end

end
