class CalcStep < ActiveRecord::Base
  belongs_to :employee
  
  serialize :step_notes, Array

  validates :employee_id, uniqueness: { scope: [:month, :employee_id, :category] }

  COLUMNS = %w(employee_id month category step_notes amount)

  def push_step(str)
    self.step_notes.push(str)
  end

  # 显示某个记录的计算过程
  def show_steps(separator = ',')
    self.step_notes.join(separator)
  end

  def final_amount(amount)
    self.amount = amount
  end

  def self.remove_items(category, month)
    CalcStep.where(category: category, month: month).delete_all
  end

  # 得到某人某月薪酬的全部计算记录
  def self.show_items(employee_id, month)
    CalcStep.where(employee_id: employee_id, month: month)
  end
end
