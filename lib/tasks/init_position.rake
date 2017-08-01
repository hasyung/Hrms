

def traverse_dir(file_path, path, name, serial_number)
  full_path = file_path + '/' + path + '/' + name
  if File.directory? full_path
    Dir.foreach(full_path) do |file|        
      if file != "." and file != ".."
        traverse_dir(file_path + '/' + path, name, file, serial_number)
      end
    end
  else
    if full_path.downcase.end_with?("doc") or full_path.downcase.end_with?("docx")
      insert_specification_by_file(full_path, path, serial_number)
    end
  end
end

def insert_specification_by_file(file_path, path_name, serial_number)
  logger = Logger.new('position_errors.txt')

  begin
    word = WordPositionParser.new(file_path)
    position_data = word.position_data
  rescue Exception => e
    puts("#{file_path}: #{e}")
    return    
  end
  
  position_name = word.position_name
  match_pattern = Regexp.new("四川航空.+#{path_name}\/")
  department_chain = file_path[match_pattern].sub(/四川航空\//, '').sub(/\/$/, '')
  departments = Department.where(name: path_name)

  department = departments.select do |dep| 
    dep_chain = dep.full_name
    dep_chain.gsub('-', '/') == department_chain
  end.first
  
  unless department
    puts("#{department_chain}不存在")
    return
  end

  # puts position_data
  # position = nil
  begin
    position_params = {
      name: position_data["岗位标识"][ "岗位名称"],
      schedule_id: Schedule.find_by(name: position_data["工作时间"][0]).try(:id) || 1,
      oa_file_no: '10000',
      budgeted_staffing: 0,
      channel_id: 0,
      position_nature_id: CodeTable::PositionNature.find_by(display_name: position_data["岗位标识"]["岗位性质"]).try(:id) || CodeTable::PositionNature.first.id,
      sort_no: department.positions.map(&:sort_no).map(&:to_i).max + 1
    }
  rescue Exception => e
    puts("#{department_chain}的#{position_name}岗位的岗位描述书格式有误")
    return
  end

  begin
    position = department.positions.find_by(name: position_params[:name])
    if position
      position.update(schedule_id: Schedule.find_by(name: position_data["工作时间"][0]).try(:id) || position.schedule_id, 
        position_nature_id: CodeTable::PositionNature.find_by(display_name: position_data["岗位标识"]["岗位性质"]).try(:id) || 
        position.position_nature_id)
    else
      position = department.positions.create(position_params)
    end
  rescue ActiveRecord::RecordInvalid => invalid
    puts("#{department_chain}创建岗位#{position_name}错误#{invalid.record.errors.messages}")
    return
  end

  puts "======="
  puts "部门名称：#{department.full_name}"
  puts "岗位名称：#{position.name}"
  # puts "岗位数据：#{position_data}"

  if position
    begin
      params = {
        duty: position_data["工作职责"].try(:join, ""), 
        personnel_permission: position_data["工作权限"][0].gsub("人事权限：", ""),
        financial_permission: position_data["工作权限"][1].gsub("财务权限：", ""),
        business_permission: position_data["工作权限"][2].gsub("业务权限：", ""),
        superior: position_data["工作联系"][0].gsub("直属上级：", ""),
        underling: position_data["工作联系"][1].gsub("直属下级：", ""),
        internal_relation: position_data["工作联系"][2].gsub("内部联系：", ""),
        external_relation: position_data["工作联系"][3].gsub("外部联系：", ""),
        qualification: position_data["任职条件"].join("")
      }
    rescue Exception => e
      puts("#{department_chain}的#{position_name}岗位的岗位描述书格式有误")
      return
    end

    if position.specification
      position.specification.update params
    else
      specification = position.build_specification params
      specification.save
    end
    puts "【#{position_name}】岗位描述书导入成功。"
  else
    puts "【#{position_name}】找不到岗位！"
  end
end