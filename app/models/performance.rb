class Performance < ActiveRecord::Base
  belongs_to :employee

  has_one :allege, class_name: "PerformanceAllege", foreign_key: 'performance_id', dependent: :destroy

  has_many :attachments, as: :attachmentable

  before_save :update_category_name, if: -> (info) { info.category_changed? }

  CATEGORY_NAME = {
    'year' => '年度',
    'month' => '月度',
    'season' => '季度'
  }

  def format_assess_time
    case self.category
    when 'year'
      return self.assess_time.year.to_s + '年'
    when 'month'
      return self.assess_time.strftime("%Y-%m")
    when 'season'
      year = self.assess_time.year.to_s + '年'
      if self.assess_time.month >= 1 && self.assess_time.month <= 3
        return year + '第一季度'
      elsif self.assess_time.month >= 4 && self.assess_time.month <= 6
        return year + '第二季度'
      elsif self.assess_time.month >= 7 && self.assess_time.month <= 9
        return year + '第三季度'
      else
        return year + '第四季度'
      end
    end
  end

  private
  def update_category_name
    self.category_name = Performance::CATEGORY_NAME[self.category]
  end
end
