require 'spreadsheet'

namespace :init do
  desc 'init social_location'
  task social_location: :environment do
    puts "开始导入社保属地"
    puts Time.now

    file_path = "#{Rails.root}/public/social/社保属地.xls"
    book = Spreadsheet.open file_path
    sheets = book.worksheets

    error_count, success_count, nil_count = 0, 0, 0

    sheets.each do |sheet|
      sheet.each_with_index do |row, index|
        next if index == 0
        employee = Employee.find_by(employee_no: row[0])
        if employee.blank?
          error_count += 1
        else
          if(employee.social_person_setup.blank?)
            employee.create_social_person_setup(
              employee_no: employee.employee_no,
              employee_name: employee.name,
              department_name: employee.department.full_name,
              position_name: employee.master_position.name,
              social_account: row[1],
              social_location: sheet.name
            )
            success_count += 1
          end
        end
      end
    end

    Employee.joins(:labor_relation).where("employee_labor_relations.display_name='合同'
      or employee_labor_relations.display_name='合同制'
      or employee_labor_relations.display_name='公务员'")
      .joins("LEFT JOIN social_person_setups ON employees.id = social_person_setups.employee_id")
      .where("social_person_setups.social_location is null").each do |employee|
      employee.create_social_person_setup(
        employee_no: employee.employee_no,
        employee_name: employee.name,
        department_name: employee.department.full_name,
        position_name: employee.master_position.name,
        social_location: '成都'
      )
      nil_count += 1
    end

    puts "成功导入 #{success_count} 条数据，系统人员花名册中找不到员工编号的有 #{error_count}】条数据，置社保个人设置数据为空的有 #{nil_count} 个"

    puts Time.now
  end

  task social_person_setups: :environment do
    # 设置年度基数为空的数据
    SocialPersonSetup.where("social_person_setups.social_location in (?)
       and (social_person_setups.pension_cardinality is null or social_person_setups.pension_cardinality = '')
       and social_person_setups.temp_cardinality is null", Welfare.get_is_annual_locations).update_all(
       "pension_cardinality = (round(rand() * 4500) + 500)")

    SocialPersonSetup.update_all("pension = round(rand()), treatment = round(rand()), unemploy = round(rand()),
      injury = round(rand()), illness = round(rand()), fertility = round(rand())")


    # 设置2014-12的薪酬缺失数据
    month = '2015-06'
    employees = Employee.joins(:social_person_setup).where("social_person_setups.social_location not in (?) and
        social_person_setups.temp_cardinality is null", Welfare.get_is_annual_locations).where("employees.id not
        in (select employees.id from employees inner join social_cardinalities on employees.id =
        social_cardinalities.employee_id where social_cardinalities.import_date = '#{month + "-01"}')")
    employees.each do |employee|
      SocialCardinality.create(employee_id: employee.id, import_month: month, import_date: month + "-01",
        employee_no: employee.employee_no, employee_name: employee.name, department_name: employee.department.full_name,
        position_name: employee.master_position.name, total: rand(500..5000))
    end
  end

  task social_change_infos: :environment do
    SocialChangeInfo.includes(employee: :social_person_setup).each do |info|
      if info.employee.social_person_setup
        info.update(social_person_setup_id: info.employee.social_person_setup.id)
      end
    end
  end

  desc "add hangzhou welfares to socials"
  task add_hangzhou_welfares_to_socials: :environment do
    item = Welfare.where(category: "socials").first
    size = item.form_data.size
    item.form_data[size] = {
       "location" => "杭州",
      "is_annual" => false,
        "pension" => {
                "is_ration" => false,
          "company_percent" => 0.8,
        "personage_percent" => 0.2,
            "company_money" => nil,
          "personage_money" => nil,
              "upper_limit" => 8000,
              "lower_limit" => 2000
      },
      "treatment" => {
                "is_ration" => false,
          "company_percent" => 0.8,
        "personage_percent" => 0.2,
            "company_money" => nil,
          "personage_money" => nil,
              "upper_limit" => nil,
              "lower_limit" => nil
      },
       "unemploy" => {
                "is_ration" => false,
          "company_percent" => nil,
        "personage_percent" => nil,
            "company_money" => nil,
          "personage_money" => nil,
              "upper_limit" => nil,
              "lower_limit" => nil
      },
         "injury" => {
                "is_ration" => false,
          "company_percent" => 0.8,
        "personage_percent" => 0.2,
            "company_money" => nil,
          "personage_money" => nil,
              "upper_limit" => nil,
              "lower_limit" => nil
      },
        "illness" => {
                "is_ration" => false,
          "company_percent" => 0.8,
        "personage_percent" => 0.2,
            "company_money" => nil,
          "personage_money" => nil,
              "upper_limit" => nil,
              "lower_limit" => nil
      },
      "fertility" => {
                "is_ration" => false,
          "company_percent" => 0.8,
        "personage_percent" => 0.2,
            "company_money" => nil,
          "personage_money" => nil,
              "upper_limit" => nil,
              "lower_limit" => nil
      }
    }
    item.save
  end

  desc "import_birth_allowances_from_2015_09"
  task import_birth_allowances_from_2015_09: :environment do
    puts "开始导入生育津贴冲抵项台账"
    errors = []
    count = 0
    file_path = "#{Rails.root}/public/生育津贴冲抵项台账_2015年9月起_.xlsx"
    book = Spreadsheet.open file_path
    sheets = book.worksheet 0
    month = Time.now.strftime("%Y-%m")
    ActiveRecord::Base.transaction do
      sheets.each_with_index do |row, index|
        next if row[0] == "部门"
        employee = Employee.find_by(employee_no:row[1])
        if employee.blank?
          errors << "人员#{row[2]}不存在"
          next
        end
        hash = {
          employee_id: employee.id,
          employee_no: row[1],
          employee_name: employee.name,
          department_name: employee.department.full_name,
          position_name: employee.try("master_position").try("name"),
          sent_date: "#{row[19].to_i}01".to_date,
          sent_amount: row[4],
          deduct_amount: row[16],
          month: month
        }
        BirthAllowance.create!(hash)
        count += 1
      end
    end
    if errors.size > 0
      puts errors.join("\r\n").red
      puts "提示: 总共处理 #{count} 行数据".yellow
      puts "警告: 有 #{errors.size} 行导入失败，失败率 #{(errors.size * 100.0/count).round(2)}% \r\n\r\n".red
    end
  end

  desc "import_social_person_setups_init"
  task import_social_person_setups_init: :environment do
    puts '开始导入... ...'
    errors = []
    count = 0
    social_location = ''
    file_path = "#{Rails.root}/public/2016年6月社保代扣.xls"
    book = Spreadsheet.open file_path
    sheets_one   = book.worksheet 0
    sheets_two   = book.worksheet 1
    sheets_three = book.worksheet 2
    sheets_four  = book.worksheet 3
    ActiveRecord::Base.transaction do
      sheets_one.each_with_index do |row, index|
        count += 1
        next if row[0] == '人员编码' || row[0].nil?
        social_location = '成都' if index == 1
        social_location = '北京' and next if row[0] == '北京外站'
        social_location = '深圳' and next if row[0] == '深圳外站'
        social_location = '广州' and next if row[0] == '广州外站'
        social_location = '上海' and next if row[0] == '上海外站'
        social_location = '杭州' and next if row[0] == '杭州外站'
        social_location = '重庆' and next if row[0] == '重庆分公司'
        employee = Employee.find_by(employee_no:row[0])
        if employee.blank?
          errors << "人员#{row[2]}不存在"
          next
        end
        social_person_setup = SocialPersonSetup.find_by(employee_id:employee.id)
        hash = {
          employee_id: employee.id,
          social_location: social_location,
          employee_no: employee.employee_no,
          employee_name: employee.name,
          department_name: employee.department.full_name,
          position_name: employee.try("master_position").try("name"),
          social_account: row[1],
          pension_cardinality: (social_location == '成都' || social_location == '广州'|| social_location == '深圳' ? nil : row[3]),
          treatment_cardinality: (social_location == '成都' || social_location == '广州'|| social_location == '深圳' ? nil : (row[4].nil? ? row[3] : row[4])),
          unemploy_cardinality: (social_location == '成都' || social_location == '广州'|| social_location == '深圳' ? nil : (row[4].nil? ? row[3] : row[4])),
          injury_cardinality: (social_location == '成都' || social_location == '广州'|| social_location == '深圳' ? nil : (row[4].nil? ? row[3] : row[4])),
          illness_cardinality: (social_location == '成都' || social_location == '广州'|| social_location == '深圳' ? nil : (row[4].nil? ? row[3] : row[4])),
          fertility_cardinality: (social_location == '成都' || social_location == '广州'|| social_location == '深圳' ? nil : (row[4].nil? ? row[3] : row[4]))
        }
        if social_person_setup.nil?
          s = SocialPersonSetup.new(hash)
          s.save
          next
        end
        social_person_setup.update(hash)
      end
      social_location = '成都'
      sheets_two.each_with_index do |row, index|
        count += 1
        next if row[0] == '员工编号' || row[0].nil? 
        employee = Employee.find_by(employee_no:row[0])
        if employee.blank?
          errors << "人员#{row[2]}不存在"
          next
        end
        social_person_setup = SocialPersonSetup.find_by(employee_id:employee.id)
        hash = {
          employee_id: employee.id,
          social_location: social_location,
          employee_no: employee.employee_no,
          employee_name: employee.name,
          department_name: employee.department.full_name,
          position_name: employee.try("master_position").try("name"),
          social_account: row[1]
        }
        if social_person_setup.nil?
          s = SocialPersonSetup.new(hash)
          s.save
          next
        end
        social_person_setup.update(hash)
      end

      sheets_three.each_with_index do |row, index|
        count += 1
        next if row[0] == '员工编号' || row[0].nil? 
        employee = Employee.find_by(employee_no:row[0])
        if employee.blank?
          errors << "人员#{row[2]}不存在"
          next
        end
        social_person_setup = SocialPersonSetup.find_by(employee_id:employee.id)
        hash = {
          employee_id: employee.id,
          social_location: social_location,
          employee_no: employee.employee_no,
          employee_name: employee.name,
          department_name: employee.department.full_name,
          position_name: employee.try("master_position").try("name"),
          social_account: row[1]
        }
        if social_person_setup.nil?
          s = SocialPersonSetup.new(hash)
          s.save
          next
        end
        social_person_setup.update(hash)
      end

      sheets_four.each_with_index do |row, index|
        count += 1
        next if row[0] == '人员编号' || row[0].nil? 
        employee = Employee.find_by(employee_no:row[0])
        if employee.blank?
          errors << "人员#{row[2]}不存在"
          next
        end
        social_person_setup = SocialPersonSetup.find_by(employee_id:employee.id)
        hash = {
          employee_id: employee.id,
          social_location: social_location,
          employee_no: employee.employee_no,
          employee_name: employee.name,
          department_name: employee.department.full_name,
          position_name: employee.try("master_position").try("name"),
          social_account: row[1]
        }
        if social_person_setup.nil?
          s = SocialPersonSetup.new(hash)
          s.save
          next
        end
        social_person_setup.update(hash)
      end
    end
    
    if errors.size > 0
      puts errors.join("\r\n").red
      puts "提示: 总共处理 #{count} 行数据".yellow
      puts "警告: 有 #{errors.size} 行导入失败，失败率 #{(errors.size * 100.0/count).round(2)}% \r\n\r\n".red
    end
  end















end