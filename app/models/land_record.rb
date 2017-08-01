class LandRecord < ActiveRecord::Base
  # 分析某个员工的某个时间段内的驻站，返回每天的驻站类型
  # 0 无 1 中期 2 长期 3 短期
  def analysis_type(end_date, start_date = nil)
    hash = {}

    @records = LandRecord.where(employee_name: employee_name)
    @records.each do |record|
      (record.start_date..record.end_date).to_a.each do |d|
        #
      end
    end

    hash
  end
end
