namespace :fix do
  desc "把之前教育经历里面的数据迁移到人员数据中去"
  task employee_education_data: :environment do 
    ActiveRecord::Base.transaction do 
      Employee::EducationExperience.all.each do |education|
        education.employee.update!(school: education.school, major: education.major)
      end

      Employee::EducationExperience.destroy_all

      bachelor_id = CodeTable::Degree.find_by(display_name: '学士')
      master_id = CodeTable::Degree.find_by(display_name: '硕士')
      Employee.all.each do |employee|
        if employee.education_background && !["大专", "大专以下"].include?(employee.education_background.display_name)
          employee.update!(degree_id: bachelor_id) if ["全日制本科", "非全日制本科"].include?(employee.education_background.display_name)
          employee.update!(degree_id: master_id) 
        end 
      end
    end
  end

  desc "将遗漏的岗位备注和技术职务导入员工表中"
  task pos_remark_and_tech_duty: :environment do
    Employee.transaction do  
      CSV.foreach("#{Rails.root}/public/pos_remark_and_tech_duty.csv") do |row|
        cols = row[0].gsub(/\s./, ",").split(",")

        puts cols.inspect

        employee = Employee.find_by(name: cols[0], employee_no: cols[1])

        if employee
          employee.update!(position_remark: cols[2], technical_duty: cols[3])
        end
      end
    end
  end

  desc "add DepName to employee transfer excel"
  task add_depname_to_excel: :environment do
    file_path = "#{Rails.root}/public/add_depname.xls"
    @book = Spreadsheet.open file_path
    @sheet = @book.worksheet 0

    @sheet.each_with_index do |row, index|
      next if index == 0
      dep = Department.where(serial_number: row[5]).first
      row[6] = dep.present? ? dep.full_name : ""
      dep = Department.where(serial_number: row[8]).first
      row[9] = dep.present? ? dep.full_name : ""
    end

    save_file_path = "#{Rails.root}/public/already_add_depname.xls"
    File.delete(save_file_path) if File.exist?(save_file_path)
    @book.write save_file_path
  end

  desc "update native_place contract address"
  task update_address: :environment do
    file_path = "#{Rails.root}/public/address_20160518.xls"
    @book = Spreadsheet.open file_path
    @sheet = @book.worksheet 0

    @sheet.each_with_index do |row, index|
      emp = Employee.find_by(employee_no: row[0])
      emp.native_place = row[1]
      emp.contact.address = row[2]
      emp.save_without_auditing
      emp.contact.save_without_auditing
      ChangeRecord.save_record('employee_update', emp).send_notification
    end
  end

  desc "修改现有“高层”“中层”后面添加“干部”两个字"
  task fix_pcategory_for_add: :environment do 
    Employee.where("pcategory='高层' or pcategory='中层'").each do |employee|
      employee.pcategory = "#{employee.pcategory}干部"
      employee.save
    end
  end
end
