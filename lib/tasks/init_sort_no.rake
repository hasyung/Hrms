namespace :init do
  desc 'init sort_no values of departments, positions, employees'
  task sort_no: :environment do
    puts "1. 初始化 部门 sort_no"
    #一级部门
    Department.where(depth: 2).each_with_index do |item, d1_index|
      item.update(d1_sort_no: d1_index + 1)
      #二级部门
      Department.where(parent_id: item.id).each_with_index do |item, d2_index|
        item.update(
          d1_sort_no: d1_index + 1,
          d2_sort_no: d2_index + 1
        )
        #三级部门
        Department.where(parent_id: item.id).each_with_index do |item, d3_index|
          item.update(
            d1_sort_no: d1_index + 1,
            d2_sort_no: d2_index + 1,
            d3_sort_no: d3_index + 1
          )
        end
      end
    end

    puts "2. 初始化 部门 sort_no 员工 sort_no department_id "
    Department.find_each do |dep|
      employees = []
      dep.positions.each_with_index do |pos, index|
        pos.update(sort_no: index + 1)
        pos.master_employees.each_with_index do |emp, index|
          employees << emp
          emp.update(
            department_id: pos.department_id
          )
        end
      end
      employees.each_with_index do |emp, index|
        emp.update(
          sort_no: index + 1
        )
      end
    end
  end


  desc "fix wrong data"
  task fix_sort_no: :environment do
    #一级部门
    Department.where(depth: 2, d1_sort_no: 0, d2_sort_no: 0, d3_sort_no: 0).each_with_index do |item, d1_index|
      item.set_sort_no
      #二级部门
      Department.where(parent_id: item.id).each_with_index do |item, d2_index|
        item.set_sort_no
        #三级部门
        Department.where(parent_id: item.id).each_with_index do |item, d3_index|
          item.set_sort_no
        end
      end
    end

    Department.find_each do |dep|
      employees = []
      dep.positions.each_with_index do |pos, index|
        pos.update(sort_no: index + 1)
        pos.master_employees.each_with_index do |emp, index|
          employees << emp
        end
      end

      employees.each_with_index do |emp, index|
        if emp.sort_no.blank?
          emp.fix_sort_no_and_department_id(dep.id)
        end
      end
    end

  end

  desc "fix positions sort_no"
  task fix_position_sort_no: :environment do
    Position.where(sort_no: nil).each do |item|
      item.fix_sort_no
    end
  end
end
