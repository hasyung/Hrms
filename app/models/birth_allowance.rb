class BirthAllowance < ActiveRecord::Base
  belongs_to :employee

  validates_presence_of :employee_id, :employee_no, :employee_name, :department_name, :position_name, :sent_date, :sent_amount
  validates :sent_amount, :deduct_amount, numericality: {greater_than_or_equal_to: 0}

  COLUMNS = %w(employee_id employee_no employee_name department_name position_name sent_date sent_amount deduct_amount month)
end
