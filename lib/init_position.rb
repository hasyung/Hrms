class InitPosition

  def self.init file_path, path, name
    department = Department.find_by(name: name)
    traverse_dir(file_path, path, name, department.serial_number)
    # puts "#{department.name}岗位和描述书导入完成。"
  end

end

