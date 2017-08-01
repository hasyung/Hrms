require 'spreadsheet'

namespace :init do 
  desc "init positino_infos2"
  task :position_infos2 => :environment do 
    puts "开始导入岗位通道和编制"
    puts Time.now

    file_path = "#{Rails.root}/public/2015年编制调整表(1).xls"
    book = Spreadsheet.open file_path
    sheet = book.worksheet 0

    count = 0

    sheet.each_with_index do |row, index|
      Position.where(name: row[3]).each do |position|
        if position.channel_id.blank? || position.channel_id == 0
          position.update channel_id: CodeTable::Channel.find_by(display_name: row[4]).try(:id), budgeted_staffing: row[5].to_i
          count += 1
        end
      end
    end
  end
end