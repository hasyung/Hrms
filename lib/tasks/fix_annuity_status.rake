namespace :fix_data do

  desc "fix dep serial_number"
  task dep_serial_number: :environment do
    puts "import xls file start"
    puts "start at #{Time.now}"

    #Logger
    log_path = Rails.root + 'log/dep_serial_number.log'
    File.delete(log_path) if File.exist?(log_path)
    logger  = Logger.new(log_path)


    file_path = "#{Rails.root}/public/DEP20150724.xls"
    book = Spreadsheet.open file_path
    sheets = book.worksheets

    #第2层级

    #特殊数据处理
    dep = Department.find_or_create_by(
      name: "绵阳运行基地",
      serial_number: "000029",
      parent_id: 1,
      nature_id: 3,
      grade_id: 3
    )
    dep.set_sort_no.save!

    sheet = sheets[0]
    sheet.each_with_index do |row, index|
      serial_number = row[0]
      dep_name = row[1]

      dep = Department.where(name: dep_name, depth: 2).first

      if dep.present?
        dep.update(serial_number: serial_number)
      else
        logger.info("#{dep_name} - #{serial_number} => 找不到")
      end
    end

    #第3层级
    Department.where(depth: 3).all.each do |dep|
      parent = dep.parent
      limit = parent.serial_number.size
      dep.serial_number.gsub!(dep.serial_number[0...limit], parent.serial_number)
      dep.save
    end

    #特殊数据处理
    parent = Department.where(serial_number: "000009", name: "工程技术分公司").first
    child  = Department.where(name: "部门领导", parent_id: parent.id).first
    child.update(name: "分公司领导") if child.present?


    parent = Department.where(serial_number: "000015", name: "重庆分公司").first
    child = parent.childrens.where(name: "国动办应急办").first
    child.destroy if child.present?

    sheet = sheets[1]
    sheet.each_with_index do |row, index|
      serial_number = row[0]
      dep_name = row[1]

      parent_dep = Department.where(serial_number: serial_number[0, (serial_number.size-3)]).first
      if parent_dep.blank?
        logger.info("#{dep_name} - #{serial_number} - #{depth}  => parent couldn't find")
        next
      end

      dep = Department.where(name: dep_name, depth: 3, parent_id: parent_dep.id).first

      if dep.present?
        dep.update(serial_number: serial_number)
      else
        logger.info("#{dep_name} - #{serial_number} => 找不到")
      end
    end

    #第4层级

    Department.where(depth: 4).all.each do |dep|
      parent = dep.parent
      limit = parent.serial_number.size
      dep.serial_number.gsub!(dep.serial_number[0...limit], parent.serial_number)
      dep.save
    end

    parent = Department.where(name: "销售部", serial_number: "000020018").first
    child = parent.childrens.where(name: "绵阳营业部").first
    child.destroy if child.present?

    parent = Department.where(name: "风险管理分部",serial_number: "000007023").first
    child = parent.childrens.where(name: "综合业务室").first
    child.destroy if child.present?

    ##特殊数据处理
    parent = Department.where(name: "航行情报资料室",serial_number: "000002007").first
    dep = Department.find_or_create_by(
      name: "航行情报资料室",
      serial_number: "000002007002",
      parent_id: parent.id,
      nature_id: 1,
      grade_id: 5
    )
    dep.set_sort_no.save!

    parent = Department.where(name: "销售部",serial_number: "000020018").first
    dep = Department.find_or_create_by(
      name: "商务代表",
      serial_number: "000020018020",
      parent_id: parent.id,
      nature_id: 1,
      grade_id: 5
    )
    dep.set_sort_no.save!

    parent = Department.where(name: "云南分公司客舱服务分部",serial_number: "000030018").first
    dep = Department.find_or_create_by(
      name: "综合室",
      serial_number: "000030018002",
      parent_id: parent.id,
      nature_id: 1,
      grade_id: 5
    )
    dep.set_sort_no.save!

    parent = Department.where(name: "董事会秘书办公室",serial_number: "000044001").first
    dep = Department.find_or_create_by(
      name: "分部领导",
      serial_number: "000044001002",
      parent_id: parent.id,
      nature_id: 1,
      grade_id: 5
    )
    dep.set_sort_no.save!

    parent = Department.where(name: "战略转型办公室",serial_number: "000044003").first
    dep = Department.find_or_create_by(
      name: "分部领导",
      serial_number: "000044003001",
      parent_id: parent.id,
      nature_id: 1,
      grade_id: 5
    )
    dep.set_sort_no.save!

    sheet = sheets[2]
    sheet.each_with_index do |row, index|
      serial_number = row[0]
      dep_name = row[1]

      parent_dep = Department.where(serial_number: serial_number[0, (serial_number.size-3)]).first
      if parent_dep.blank?
        logger.info("#{dep_name} - #{serial_number} - #{depth}  => parent couldn't find")
        next
      end

      dep = Department.where(name: dep_name, depth: 4, parent_id: parent_dep.id).first

      if dep.present?
        dep.update(serial_number: serial_number)
      else
        logger.info("#{dep_name} - #{serial_number} => 找不到")
      end
    end
  end


  desc "export depth=4 department"
  task export_dep_4: :environment do
    puts "开始: #{Time.now}"
    file_name = "#{Time.now.to_i}_temp.xls"
    file_path = "#{Rails.root}/log/#{file_name}"

    book = Spreadsheet::Workbook.new
    sheet = book.create_worksheet

    records = Department.where(depth: 4).order(:serial_number)
    counter = 0
    records.each do |item|
      counter = counter + 1
      sheet[counter, 0]  = item.serial_number
      sheet[counter, 1]  = item.name
    end

    book.write file_path
    puts "commit"
  end

  desc "import employees annuity"
  task fix_annuity_status: :environment do
    puts "import annuity"
    puts "开始: #{Time.now}"

    file_path = "#{Rails.root}/public/annuity/annuity.xls"
    book = Spreadsheet.open file_path
    sheets = book.worksheets

    logger  = Logger.new(File.join(Rails.root, 'log', 'annuity.log'))

    sheets.each do |sheet|
      sheet.each_with_index do |row, index|
        next if index == 0
        employee_no = row[0]
        name        = row[1]
        identity_no = row[2].upcase
        mobile      = row[3]
        cardinality = row[4]

        @employee = Employee.unscoped.includes([:contact]).find_by(employee_no: employee_no)

        if @employee.blank?
          logger.info("#{employee_no},#{name},#{identity_no}--Not Found")
          next
        end

        if @employee.identity_no != identity_no
          logger.info("#{employee_no},#{name},#{identity_no}--Failed")
        else
          @employee.contact.update(mobile: mobile.to_i.to_s) if @employee.contact.mobile != mobile
          @employee.update(
            annuity_cardinality: cardinality,
            annuity_account_no: "0",
            annuity_status: true
          )
        end
      end
    end
    puts "完成: #{Time.now}, 失败日志参见log/annuity.log"
  end

  desc "rake test annuity_apply data"
  task annuity_apply_data: :environment do
    @employee_labor_relation = Employee::LaborRelation.where(display_name: '合同制').first

    Employee.where(labor_relation_id: @employee_labor_relation.id).order("RAND()").limit(50).each do |employee|
      message = employee.annuity_status ? "申请加入" : "申请退出"
      department_name = employee.department.full_name

      apply = employee.annuity_applies.new(
        employee_name:     employee.name,
        employee_no:       employee.employee_no,
        department_name:   department_name,
        apply_category:    message,
        status:            false
      ).save()
    end
  end

end
