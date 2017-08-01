class Holiday < ActiveRecord::Base
  # 节假日API地址 http://www.ddung.org/tool/jiari/?d=2015
  # http://www.easybots.cn/api/holiday.php?m=201501,201502,201503,201504,201505,201506,201507,201508,201509,201510,201511,201512
  # http://www.easybots.cn/api/holiday.php?m=201601,201602,201603,201604,201605,201606,201607,201608,201609,201610,201611,201612
  # http://www.ddung.org/tool/jiari/
  # http://hbwanghai.blog.163.com/blog/static/199297147201371213052417/
  validates :record_date, :flag, presence: true
  validates :record_date, uniqueness: true

  scope :customed, -> { where(is_custom: true, flag: 2) }

  def self.before_working_days(days, date = Date.today)
    index = 1
    free_days = Holiday.all.map(&:record_date)

    while index <= days
      index += 1 unless free_days.include?(date.prev_day)
      date = date.prev_day
    end

    date
  end
end
