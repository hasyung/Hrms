class Welfare < ActiveRecord::Base
  serialize :form_data, Array

  SOCIAL_TYPES = %w(pension treatment unemploy injury illness fertility)
  SOCIAL_OTHER_TYPES = %w(treatment unemploy injury illness fertility)

  validate :social_format, if: -> (welfare) { welfare.category == 'socials' }

  def check_socials
    self.form_data.each do |social|
      if social["pension"]["upper_limit"].blank? || social["pension"]["upper_limit"] == 0 || 
        social["pension"]["lower_limit"].blank? || social["pension"]["lower_limit"] == 0
        return "请设置社保全局数据"
      end
    end
    nil
  end

  def self.get_is_annual_locations
    socials = Welfare.find_by(category: 'socials').form_data
    socials.inject([]) do |arr, social| 
      arr << social['location'] if social['is_annual']
      arr
    end
  end

  def social_format
    errors.add(:form_data, "#{check_social_format}数据格式错误") if check_social_format
  end

  private
  def check_social_format
    self.form_data.each do |social|
      if  social["pension"].blank? || social["pension"]["upper_limit"].blank? || 
        social["pension"]["upper_limit"] == 0 || social["pension"]["lower_limit"].blank? || 
        social["pension"]["lower_limit"] == 0 || check_percent_money(social, "pension") || 
        social["treatment"].blank? || check_percent_money(social, "treatment") || 
        social["unemploy"].blank? || check_percent_money(social, "unemploy") || 
        social["injury"].blank? || check_percent_money(social, "injury") || 
        social["illness"].blank? || check_percent_money(social, "illness") || 
        social["fertility"].blank? || check_percent_money(social, "fertility")
        return social["location"]
      end
    end
    nil
  end

  def check_percent_money(social, type)
    social[type]["upper_limit"] ||= 0
    social[type]["lower_limit"] ||= 0
    return true if social[type]["upper_limit"] < social[type]["lower_limit"]
    if social[type]["is_ration"]
      social[type]["company_money"] ||= 0
      social[type]["personage_money"] ||= 0
      return true if social[type]["company_money"] < 0 || social[type]["personage_money"] < 0
    else
      social[type]["company_percent"] ||= 0
      social[type]["personage_percent"] ||= 0
      return true if social[type]["company_percent"] < 0 || social[type]["company_percent"] > 100
      return true if social[type]["personage_percent"] < 0 || social[type]["personage_percent"] > 100
    end
    false
  end
end
