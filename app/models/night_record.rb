class NightRecord < ActiveRecord::Base
  def is_invalid
    (self.shifts_type == "两班倒" && self.night_number > 16) || (self.shifts_type == "三班倒" && self.night_number > 11) || (self.shifts_type == "四班倒" && self.night_number > 8)
  end

  def calc_amount
    self.night_number * self.subsidy.to_f
  end
end
