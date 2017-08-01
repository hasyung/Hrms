class CreateWelfares < ActiveRecord::Migration
  def change
    create_table :welfares do |t|
      t.string :category, index: true, unique: true #类型（社保："socials"）
      t.text   :form_data #array

      t.timestamps null: false
    end

    form_data = %w(成都 重庆 北京 上海 广州 深圳).inject([]) do |arr, location|
      arr << {
        'location' => location,
        'pension_insure' => {
          'upper_limit' => nil, 
          'lower_limit' => nil
        }, 
        'other_insure' => {
          'upper_limit' => nil,
          'lower_limit' => nil
        },
        'pension' => { #养老
          'is_ration' => false, #是否定额
          'company_percent' => nil,
          'personage_percent' => nil,
          'company_money' => nil,
          'personage_money' => nil
        },
        'treatment' => { #医疗
          'is_ration' => false,
          'company_percent' => nil,
          'personage_percent' => nil,
          'company_money' => nil,
          'personage_money' => nil
        },
        'unemploy' => { #失业
          'is_ration' => false,
          'company_percent' => nil,
          'personage_percent' => nil,
          'company_money' => nil,
          'personage_money' => nil
        },
        'injury' => { #工伤
          'is_ration' => false,
          'company_percent' => nil,
          'personage_percent' => nil,
          'company_money' => nil,
          'personage_money' => nil
        },
        'illness' => { #大病
          'is_ration' => false,
          'company_percent' => nil,
          'personage_percent' => nil,
          'company_money' => nil,
          'personage_money' => nil
        },
        'fertility' => { #生育
          'is_ration' => false,
          'company_percent' => nil,
          'personage_percent' => nil,
          'company_money' => nil,
          'personage_money' => nil
        }
      }
    end

    Welfare.create(category: 'socials', form_data: form_data)

  end
end
