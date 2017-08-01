require_relative './../../common_meta/object'

module Excel
  class PerformanceTempWriter
    class << self
      def export_temp(records)
        file_name = CGI::escape("绩效模板_#{Time.now.to_i}.xls")
        file_path = "#{Rails.root}/public/export/tmp/#{file_name}"

        book = Spreadsheet::Workbook.new
        sheet = book.create_worksheet

        #填写第一行
        [
          "人员编码", "一正部门", "一副部门", "二正部门", "级别", "姓名",
          "营销标示", "月度分配基数", "考核结果", "部门当月分配结果",
          "部门留存分配结果", "分析系数"
        ].each_with_index do |title, index|
          sheet[0, index] = title
        end

        counter = 0
        records.find_each do |item|
          counter = counter + 1
          departments = item.master_position.department.parent_chain

          #写入数据
          sheet[counter, 0]  = item.employee_no
          sheet[counter, 1]  = departments.select{|d| d.grade.name == 'branch_company' || d.grade.name == 'positive' || d.grade.name == 'scal'}.first.try(:name)
          sheet[counter, 2]  = departments.select{|d| d.grade.name == 'deputy'}.first.try(:name)
          sheet[counter, 3]  = departments.select{|d| d.grade.name == 'secondly_positive'}.first.try(:name)
          sheet[counter, 4]  = item.duty_rank.try(:display_name)
          sheet[counter, 5]  = item.name
          sheet[counter, 6]  = ""
          sheet[counter, 7]  = item.month_distribute_base
          sheet[counter, 8]  = ""
          sheet[counter, 9]  = ""
          sheet[counter, 10] = ""
          sheet[counter, 11] = ""
        end

        book.write file_path

        {
          path: file_path,
          filename: file_name
        }

      end
    end
  end
end
