namespace :init do 
  desc "init confirmed_positions"
  task :confirmed_positions => :environment do
    # 添加机构
    # dep_names = %w(公司领导 公司高层管理干部)
    # nature_id = CodeTable::DepartmentNature.find_by(display_name: '机关部门').id
    # grade_id = CodeTable::DepartmentGrade.find_by(name: 'positive').id
    # dep_names.each do |name| 
    #   Department.create!(name: name, grade_id: grade_id, nature_id: nature_id, parent_id: 1) unless Department.find_by(name: name)
    # end

    # 添加岗位
    file_path = "#{Rails.root}/public"
    dep_path = '四川航空'
    
    InitPosition.init(file_path, dep_path, '商务委员会')
    InitPosition.init(file_path, dep_path, '计划财务部')
    InitPosition.init(file_path, dep_path, '人力资源部')
    InitPosition.init(file_path, dep_path, '飞行部')
    InitPosition.init(file_path, dep_path, '运行控制中心')
    InitPosition.init(file_path, dep_path, '空保大队')

    # departments = Department.where("name like '%公司领导%' or CHAR_LENGTH(serial_number) > 6")
    # specification_attributes = {
    #   duty: "无",
    #   personnel_permission: "无",
    #   financial_permission: "无",
    #   business_permission: "无",
    #   superior: "无",
    #   underling: "无",
    #   internal_relation: "无",
    #   external_relation: "无",
    #   qualification: "无"
    # }
    # departments.each do |department|
    #   pos = department.positions.new(name: '待定', budgeted_staffing: 0, oa_file_no: '添加待定01', is_confirmed: true,
    #     channel_id: CodeTable::Channel.find_by(display_name: '服务A').try(:id) || CodeTable::Channel.first.id, schedule_id: 1)
      
    #   pos.save_without_auditing
    #   pos.fix_sort_no

    #   pos.create_specification(specification_attributes)
    # end

    # Position.find_each do |pos|
    #   specification = pos.specification
    #   specification.manual_save_pdf unless File.exist?(specification.pdf_path)
    # end
    # puts "共创建【#{departments.size}】个待定岗位"
  end
end