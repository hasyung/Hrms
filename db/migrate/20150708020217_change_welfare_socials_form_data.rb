class ChangeWelfareSocialsFormData < ActiveRecord::Migration
  def change
    form_data = %w(成都 重庆 北京 上海 广州 深圳).inject([]) do |arr, location|
      arr << {
        'location' => location,
        'is_annual' => %w(重庆 北京 上海).include?(location),
        'pension' => { #养老
          'is_ration' => false, #是否定额
          'company_percent' => 0.8,
          'personage_percent' => 0.2,
          'company_money' => nil,
          'personage_money' => nil,
          'upper_limit' => 8000,
          'lower_limit' => 2000
        },
        'treatment' => { #医疗
          'is_ration' => false,
          'company_percent' => 0.8,
          'personage_percent' => 0.2,
          'company_money' => nil,
          'personage_money' => nil,
          'upper_limit' => nil,
          'lower_limit' => nil
        },
        'unemploy' => { #失业
          'is_ration' => false,
          'company_percent' => nil,
          'personage_percent' => nil,
          'company_money' => nil,
          'personage_money' => nil,
          'upper_limit' => nil,
          'lower_limit' => nil
        },
        'injury' => { #工伤
          'is_ration' => false,
          'company_percent' => 0.8,
          'personage_percent' => 0.2,
          'company_money' => nil,
          'personage_money' => nil,
          'upper_limit' => nil,
          'lower_limit' => nil
        },
        'illness' => { #大病
          'is_ration' => false,
          'company_percent' => 0.8,
          'personage_percent' => 0.2,
          'company_money' => nil,
          'personage_money' => nil,
          'upper_limit' => nil,
          'lower_limit' => nil
        },
        'fertility' => { #生育
          'is_ration' => false,
          'company_percent' => 0.8,
          'personage_percent' => 0.2,
          'company_money' => nil,
          'personage_money' => nil,
          'upper_limit' => nil,
          'lower_limit' => nil
        }
      }
    end

    welfare = Welfare.find_or_create_by(category: 'socials')
    welfare.update(form_data: form_data)
  end
end
