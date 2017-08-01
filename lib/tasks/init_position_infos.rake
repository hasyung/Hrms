require 'spreadsheet'

namespace :init do 
  desc "init positino_infos"
  task :position_infos => :environment do 
    puts "开始导入岗位通道和编制"
    puts Time.now

    file_path = "#{Rails.root}/public/2015年编制调整表(1).xls"
    book = Spreadsheet.open file_path
    sheet = book.worksheet 0

    count = 0

    sheet.each_with_index do |row, index|
      yizheng, yifu, erzheng = nil, nil, nil
      if row[0]
        yizheng = Department.find_by(name: row[0])
        unless yizheng
          puts "第【#{index + 1}】行找不到机构（#{row[0]}）"
          next
        end
      end
      if row[1]
        yifu = yizheng ? yizheng.childrens.find_by(name: row[1]) : Department.find_by(name: row[1])
        unless yifu
          puts "第【#{index + 1}】行找不到机构（#{row[1]}）"
          next
        end
      end
      if row[2]
        erzheng = yifu ? yifu.childrens.find_by(name: row[2]) : yizheng.childrens.find_by(name: row[2])
        unless erzheng
          puts "第【#{index + 1}】行找不到机构（#{row[2]}）"
          next
        end
      end

      positions = nil
      if erzheng
        positions = erzheng.positions
      elsif yifu
        positions = yifu.positions
      elsif yizheng
        positions = yizheng.positions
      else
        puts("第【#{index + 1}】行找不到")
        next
      end
      
      position = positions.find_by(name: row[3])
      if position
        position.update channel_id: CodeTable::Channel.find_by(display_name: row[4]).try(:id), budgeted_staffing: row[5].to_i
      else
        puts "第【#{index + 1}】行找不到岗位（#{row[3]}）"
        next
      end
      count += 1
      # puts("第【#{index + 1}】行导入岗位通道和编制成功！")
    end

    puts Time.now
    puts "共成功导入【#{count}】个岗位通道和编制"

  end
end