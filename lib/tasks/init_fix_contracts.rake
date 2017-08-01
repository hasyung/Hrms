namespace :init do
  desc "修复合同记录员工id"
  task fix_contracts_employee_id: :environment do
    sql = []

    Contract.find_each do |contract|
      e = Employee.unscoped.where(name: contract.employee_name, employee_no: contract.employee_no).first

      if e.present?
        sql << "UPDATE contracts SET employee_id = #{e.id} where id = #{contract.id}"
      else
        sql << "UPDATE contracts SET employee_id = 0 where id = #{contract.id}"
      end

      puts sql.size
    end

    ActiveRecord::Base.transaction do
      sql.each {|x| ActiveRecord::Base.connection.execute(x)}
      Contract.where(due_time: 0).update_all(end_date: nil)
    end
  end

  desc "重新合并员工合同记录"
  task remerge_contract_record: :environment do
    Contract.where(original: true, merged: true).update_all(merged: false)
    Contract.where(original: false).destroy_all
    Contract.where(original: true, end_date: "1990-01-01", due_time: '无固定').update_all(end_date: nil)
    Contract.where(original: true, end_date: "1900-01-01", due_time: '无固定').update_all(end_date: nil)

    Contract.where("employee_id != 0").group(:employee_id).pluck(:employee_id).each do |employee_id|
      puts "user_id #{employee_id}"
      employee = Employee.unscoped.where(id: employee_id).first
      contracts = employee.contracts.where(original: true, merged: false).order(:start_date)

      contracts.each do |item|
        puts "user_id ==========> #{employee.id} contract_id ====> #{item.id}"
        item.judge_merge_contract
      end
    end

    Contract.where("employee_id = 0").each do |item|
      Contract.init_merge_contract(item)
      item.update(merged: true)
    end
  end

  desc "遍历员工转合同制 合同时间"
  task fix_employee_info_by_contract: :environment do
    log_path = Rails.root + 'log/contract_fix_date.log'
    File.delete(log_path) if File.exist?(log_path)
    logger  = Logger.new(log_path)

    book = Spreadsheet.open "#{Rails.root}/public/contract_fix_date.xls"
    sheet = book.worksheet 0

    sheet.each_with_index 1 do |row, index|
      employee = Employee.unscoped.where(employee_no: row[1], name: row[0]).first
      if employee.blank?
        logger.info("#{index} -- #{row[0]} -- #{row[1]} couldn't find") and next
      end

      employee.update(change_contract_system_date: row[2]) if row[2].present?
      employee.update(change_contract_date: row[3]) if row[3].present?
    end
  end
end
