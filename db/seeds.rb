# puts '系统设置配置信息...'
# puts '-------'
# SystemConfig.create(key: 'bits_counter', value: 0)
# puts '完成 设置权限位数'

# puts '开始系统码表设置'

# grade_root = CodeTable::DepartmentGrade.create(name: 'scal', level: 0, index: 1, readable_index: 1, display_name: '四川航空')
# grade_fen = CodeTable::DepartmentGrade.create(name: 'branch_company', level: 1, index: 3, readable_index: 2, display_name: '分公司')
# grade_yizheng = CodeTable::DepartmentGrade.create(name: 'positive', level: 1, index: 1, readable_index: 4, display_name: '一正级')
# grade_yifu = CodeTable::DepartmentGrade.create(name: 'deputy', level: 1, index: 2, readable_index: 8, display_name: '一副级')
# grade_erzheng = CodeTable::DepartmentGrade.create(name: 'secondly_positive', level: 2, index: 1, readable_index: 16, display_name: '二正级')

# producation_department = CodeTable::DepartmentNature.create(display_name: "生产部门")
# organ_department = CodeTable::DepartmentNature.create(display_name: "机关部门")
# branch_base = CodeTable::DepartmentNature.create(display_name: "分公司基地")

# code_table_hash = YAML.load(File.read("#{Rails.root}/config/code_table.yml"))
# code_table_hash.each do |key, display_names|
#   klass = key.constantize
#   display_names.each do |name|
#     klass.create(display_name: name)
#   end
# end

# %w(标准工时制 综合工时制 不定时工时制 标准工作制 标准工作时).each do |name|
#   Schedule.create(display_name: name, name: name)
# end

# %w(领导 干部 员工).each_with_index do |name, index|
#   CodeTable::Category.create(display_name: name, key: %w(LingDao GanBu YuanGong)[index])
# end

# %w(专职 兼职).each do |name|
#   CodeTable::PositionNature.create(display_name: name)
# end

# puts "系统码表设置完成"

# puts "开始设置机构"
# dep_root = Department.create(name: "四川航空", grade: grade_root, status: 'active', depth: 1, serial_number: '000', parent_id: 0)
# Excel::DepartmentImporter.new("#{Rails.root}/public/department.xlsx").call
# puts '机构初识设置完成'


# puts "开始设置岗位"
# puts Time.now
file_path = "#{Rails.root}/public"
time = DateTime.now.to_s
# file_path = "/Users/ant"
dep_path = '四川航空'

# InitPosition.init(file_path, dep_path, '保卫部')
# InitPosition.init(file_path, dep_path, '北京运行基地')
# InitPosition.init(file_path, dep_path, '标准管理部')
# InitPosition.init(file_path, dep_path, '采购管理部')
# InitPosition.init(file_path, dep_path, '党委办公室')
# InitPosition.init(file_path, dep_path, '地面服务部')
# InitPosition.init(file_path, dep_path, '法务审计部')
# InitPosition.init(file_path, dep_path, '飞行部')
# InitPosition.init(file_path, dep_path, '飞行技术管理部')
#(工程技术分公司/成都维修分部)下属科室无法识别
# InitPosition.init(file_path, dep_path, '工程技术分公司')
# InitPosition.init(file_path, dep_path, '工会办公室')
# InitPosition.init(file_path, dep_path, '哈尔滨运行基地')
# InitPosition.init(file_path, dep_path, '杭州运行基地')
# InitPosition.init(file_path, dep_path, '航空安全监察部')
# InitPosition.init(file_path, dep_path, '航空医疗卫生中心')
# InitPosition.init(file_path, dep_path, '后勤保障部')
# InitPosition.init(file_path, dep_path, '机务工程部')
# InitPosition.init(file_path, dep_path, '纪检（监察）办公室')
# InitPosition.init(file_path, dep_path, '计划财务部')
# InitPosition.init(file_path, dep_path, '客舱服务部')
# InitPosition.init(file_path, dep_path, '空保大队')
# InitPosition.init(file_path, dep_path, '女职工委员会')
# InitPosition.init(file_path, dep_path, '品牌质量管理部')
# InitPosition.init(file_path, dep_path, '企业管理部')
# InitPosition.init(file_path, dep_path, '企业文化部')
# InitPosition.init(file_path, dep_path, '人力资源部')
# InitPosition.init(file_path, dep_path, '三亚运行基地')
# InitPosition.init(file_path, dep_path, '商务委员会')
# InitPosition.init(file_path, dep_path, '团委（青年工作部）')
# InitPosition.init(file_path, dep_path, '物流部')
# InitPosition.init(file_path, dep_path, '西安运行基地')
# InitPosition.init(file_path, dep_path, '信息服务部')
# InitPosition.init(file_path, dep_path, '云南分公司')
# InitPosition.init(file_path, dep_path, '运行控制中心')
# InitPosition.init(file_path, dep_path, '公司领导')
# InitPosition.init(file_path, dep_path, '公司高层管理干部')
# InitPosition.init(file_path, dep_path, '重庆分公司')
# InitPosition.init(file_path, dep_path, '专家委员会')
# InitPosition.init(file_path, dep_path, '总经理工作部')
# InitPosition.init(file_path, dep_path, '总经理值班室（国动办应急办）')
# InitPosition.init(file_path, dep_path, '文化传媒广告公司')
# InitPosition.init(file_path, dep_path, '商旅公司')
# InitPosition.init(file_path, dep_path, '校修中心')


# puts Time.now
# puts '岗位设置完成'

# 设置待定岗位
# Department.where(depth: 2).each do |dep|
#   dep.positions.create(
#     name: "待定",
#     schedule_id: 1,
#     oa_file_no: '10000',
#     budgeted_staffing: 0,
#     channel_id: 0,
#     is_confirmed: true
#   )
# end
# pos1 = Department.find_by(full_name: '地面服务部-车队').positions.create(
#   name: "行政管理员",
#   schedule_id: 1,
#   oa_file_no: '10000',
#   budgeted_staffing: 0,
#   channel_id: 0,
#   is_confirmed: true
# )

# pos2 = Department.find_by(full_name: '物流部-市场业务管理室').positions.create(
#   name: "培训管理员",
#   schedule_id: 1,
#   oa_file_no: '10000',
#   budgeted_staffing: 0,
#   channel_id: 0,
#   is_confirmed: true
# )

# pos1.create_specification
# pos2.create_specification

# pos1.fix_sort_no
# pos2.fix_sort_no

# 导入员工的临时任务
# importer = Excel::EmployeeImporter.new("#{Rails.root}/public/employee.xls")
# importer.parse_data

# unless importer.has_errors?
#   importer.import
# end
# CSV.foreach("#{Rails.root}/employee.csv") do |row|
#   result = row[0].split(' ')[1]

#   `echo "#{result}" >> import.txt`
# end



# `echo "=============警告日志区==================" >> employee_errors.txt`
# importer.errors.each do |error|
#   `echo "#{error}" >> employee_errors.txt`
# end

# %w(男 女).each do |name|
#   CodeTable::Gender.create(display_name: name)
# end

# %w(已婚 未婚 离异 丧偶).each do |name|
#   CodeTable::MaritalStatus.create(display_name: name)
# end

# %w(学士 硕士 博士).each do |name|
#   CodeTable::Degree.create(display_name: name)
# end

# %w(群众 团员 党员).each do |name|
#   CodeTable::PoliticalStatus.create(display_name: name)
# end

# %w(试用期员工 正式员工 离职员工 返聘员工).each do |name|
# 	Employee::EmploymentStatus.create(display_name: name)
# end
# puts "开始设置人员"
# puts Time.now

# parser = Excel::EmployeeParser.new("#{Rails.root}/public/employees.xls")
# employee_params = parser.call
# Employee.batch_create(employee_params)

# puts Time.now
# puts '岗位下人员设置完成'

# puts '做初始化快照。。。'

# init_change_log = DepartmentChangeLog.new(title: '初始化数据', oa_file_no: 'scal-0001', dep_name: dep_root.name, department_id: 1, step_desc: '初始化川航机构数据')
# # 
# Department.active_change!(init_change_log) #, @first_employee)



# # init_change_log = DepartmentChangeLog.create(oa_file_no: '00001', title: '初始化数据')
# # Department.take_snapshot init_change_log.id


# Audit.delete_all

#execute :rake, "init:flow_permission"

# Employee.where.not(bit_value: '0').each do |empl|
#   `echo "#{empl.employee_no} #{empl.bit_value}" >> "public/bit_value.csv"`
# end

# CSV.foreach("#{Rails.root}/public/bit_value.csv") do |row|
#   cols = row[0].split(' ')

#   employee = Employee.find_by(employee_no: cols[0])
#   employee.update(bit_value: cols[1])
# end

# CSV.foreach("#{Rails.root}/public/flyer.csv") do |row|
#   cols = row[0].split(' ')
#   full_name = cols.first(3).join("-")
#   department = Department.find_by(full_name: full_name)
#   employee = Employee.find_by(employee_no: cols[4], name: cols[3])
#   position = department.positions.find_by(name: '飞行员')

#   puts "==========="
#   puts cols.inspect
#   puts department.name 
#   puts employee.name 
#   puts position.name

#   if employee && department && position
#     employee.work_experiences.delete_all
#     employee.employee_positions.delete_all

#     employee_position = EmployeePosition.new(employee_id: employee.id, position_id: position.id, category: '主职', sort_index: 0)
#     employee_position.save_without_auditing
#     employee.fix_sort_no_and_department_id(department.id)
#   end
# end

# position = Department.find_by(full_name: '标准管理部-运行手册管理室').positions.find_by(name: '飞行员')
# position.update(employees_count: position.employees.count)

# Audit.where("created_at > ?", "2015-12-10T18:24:17+08:00").delete_all

# 2015-12-11




# employee_ids = Audit.employee_record.map(&:associated_id).uniq
# CSV.foreach("#{Rails.root}/public/templ_user.csv") do |row|
#   cols = row[0].split(' ')
#   last_tow_cols = cols.last(2)
  
#   puts "======"
#   puts cols.inspect
#   puts last_tow_cols.inspect
  
#   department_name = (cols - last_tow_cols).join('-')
#   employee = Employee.unscoped.find_by(employee_no: last_tow_cols.first)

#   next if employee_ids.include?(employee.id)

#   unless employee && employee.department.full_name == department_name && employee.master_position && employee.master_position.name == last_tow_cols.last
#     `echo "#{row[0]}" >> employee.csv`
#   end
# end

# Department.find_by(name: '公司高层管理干部').update(full_name: '四川航空-公司高层管理干部')
# CSV.foreach("#{Rails.root}/employee.csv") do |row|
#   cols = row[0].split(' ')
#   last_tow_cols = cols.last(2)
#   department_name = (cols - last_tow_cols).join('-')
#   employee = Employee.find_by(employee_no: last_tow_cols.first)
#   department = Department.find_by(full_name: department_name)
#   position = department.positions.find_by(name: last_tow_cols.last)

#   puts "========"
#   puts department_name.inspect
#   puts last_tow_cols.first.inspect
#   puts last_tow_cols.last.inspect

#   employee.work_experiences.delete_all
#   employee.employee_positions.delete_all

#   emp_pos = EmployeePosition.new(employee_id: employee.id, position_id: position.id, category: '主职', sort_index: 0)
#   emp_pos.save_without_auditing
#   work_experience = employee.work_experiences.new(
#     start_date: Date.today,
#     company: '四川航空',
#     department: department_name,
#     position: position.name + "(#{position.category})",
#     end_date: "至今",
#     category: "after"
#   )
#   work_experience.save_without_auditing
#   employee.fix_sort_no_and_department_id(department.id)
# end

# 修改工作经历中的岗位名称，删除冗余数据
# Employee::WorkExperience.where("position like ? OR position like ? OR position like ?", "%主职", "%兼职", "%代理").each do |work|
#   position = work.position.sub("主职", "(主职)").sub("兼职", "(兼职)").sub("代理", "(代理)")
#   work.assign_attributes(position: position)
#   work.save_without_auditing
# end

# Employee::WorkExperience.where.not(end_date: '至今').each do |work|
#   Employee::WorkExperience.where(department: work.department, position: work.position, employee_id: work.employee_id, end_date: '至今').delete_all
# end

#迁移人员的职称数据
# Employee.transaction do 
#   Employee.all.each_with_index do |empl, index|
#     job_title = Employee::JobTitle.find_by(id: empl.job_title_id)
    
#     puts "===第#{index + 1}：#{empl.name}==="
    
#     next unless job_title
#     empl.assign_attributes(job_title: job_title.display_name)
#     empl.save_without_auditing
#   end
# end

#修复部分机构人员的职称和职称级别
# Employee.transaction do 
#   Dir["#{Rails.root}/public/职称级别/*"].each do |path|
#     file_name = Pathname.new(path).basename
#     sheet = Spreadsheet.open(path).worksheet(0)
    
#     sheet.each_with_index do |col, index|
#       next if index == 0
      
#       puts "正在解析#{file_name}的第#{index + 1}行"

#       name, emp_no = col[0], col[1]
#       job_title, job_title_degree = col[2], Employee::JobTitleDegree.find_by(display_name: col[3])
#       employee = Employee.find_by(employee_no: emp_no)
      
#       next unless employee 

#       employee.assign_attributes(job_title: job_title, job_title_degree_id: job_title_degree.id)
#       employee.save_without_auditing
#     end
#   end
# end

# 修复干部工作经历的开始时间
# category_id = CodeTable::Category.find_by(display_name: '干部')
# emp_id = Employee.where(category_id: category_id).pluck(:id)
# Employee::WorkExperience.where(employee_id: emp_id).each_with_index do |work, index|
#   puts "正在解析#{index + 1}"
#   work.assign_attributes(start_date: "2014-09-25")
#   work.save_without_auditing
# end

# 导入部分人员工作经历
# Employee.find_by(employee_no: '000131').work_experiences.delete_all
# sheet = Spreadsheet.open("#{Rails.root}/public/人力资源部任职记录和工作经历.xls").worksheet(0)
# sheet.each_with_index do |cols, index|
#   next if index == 0

#   puts "========#{index + 1}行#{cols[2]}=========="
#   empl = Employee.find_by(employee_no: cols[3])
#   work = empl.work_experiences.build(company: '四川航空', department: cols[4], position: cols[5], start_date: cols[0], end_date: cols[1], category: 'after')
#   work.save_without_auditing
# end

# 迁移人员分类到工作经历中
# Employee.all.each do |employee|
#   employee.work_experiences.where.not(category: "before").each do |work|
#     work.assign_attributes(employee_category: employee.category.try(:display_name))
#     work.save_without_auditing
#   end
# end

# grade_id = CodeTable::DepartmentGrade.find_by(display_name: '一副级').id
# full_names = %w(商务委员会-销售部-成都营业部 商务委员会-销售部-重庆营业部 商务委员会-销售部-昆明营业部 商务委员会-销售部-北京营业部 商务委员会-销售部-哈尔滨营业部 商务委员会-销售部-广州营业部 商务委员会-销售部-上海营业部 商务委员会-销售部-西安营业部 商务委员会-销售部-杭州营业部)
# Department.where(full_name: full_names).each do |dep|
#   dep.assign_attributes(grade_id: grade_id)
#   dep.save
# end

# department = Department.find_by(full_name: '工程技术分公司-成都维修分部')
# department.childrens.each do |dep|
#   positions = dep.positions
#   pos_names = positions.pluck(:name)
#   pos_dup_names = pos_names.group_by{|name| name}.select{|key, value| value.count > 1}.map(&:first)

#   if pos_dup_names.count > 0
#     pos_dup_names.each do |name|
#       selected_positions = positions.where(name: name)
#       if selected_positions.where.not(employees_count: 0).count != 0
#         puts "存在有人员的"
#         puts selected_positions.pluck(:name).inspect
#         selected_positions.where(employees_count: 0).delete_all
#       else
#         puts "没有人员的"
#         puts selected_positions.pluck(:name).inspect
#         ids = selected_positions.pluck(:id)
#         ids.shift
#         Position.where(id: ids).delete_all
#       end
#     end
#   end
# end

# Audit.where("created_at > ?", time).delete_all

