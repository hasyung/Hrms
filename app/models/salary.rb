class Salary < ActiveRecord::Base
  serialize :form_data, Hash

  validates_uniqueness_of :category

  # 根据列名(column_name)和工作年限(year)获取amount
  def get_amount_by_column(column_name, year)
    amount = 0
    column = self.form_data["flag_names"].select{|k, v|v == column_name}.keys.first
    self.form_data["flags"].each do |k, v|
      if v[column].present? && v[column]["expr"].include?("%{join_scal_years}")
        expr = v[column]["expr"]
        index = expr.index("%{join_scal_years}")
        expr = expr[index..-1]
        if expr.size > 28
          index_a = expr.index(" and ")
          index_o = expr.index(" or ")
          if index_a && index_o
            if index_a < index_o
              @dex = index_a
            else
              @dex = index_o
            end
          elsif index_a
            @dex = index_a
          else
            @dex = index_o
          end
          if @dex
            @dex = @dex - 2 if expr[@dex - 1] == ")"
            expr = expr[0..@dex - 1]
          end
        end
            
        amount = v["amount"] if self.instance_eval(expr.sub("%{join_scal_years}", year.to_s)) && v["amount"] > amount
      end
    end
    amount
  end

  # 根据金额(amount)获取档级(base_channel)
  def get_flag_by_amount(amount)
    channel = nil
    self.form_data["flags"].each do |k, v|
      channel = k if v["amount"] == amount
    end
    channel
  end

  # 根据金额(amount, column)按上浮或下靠获取档级(base_channel)和新的amount
  def get_flag_and_amount(column, amount, is_up)
    diff_money = nil
    will_amount = 0
    flag = nil
    self.form_data["flags"].each do |k, v|
      if v[column].present?
        if is_up
          if diff_money.blank? || (v["amount"] >= amount && diff_money > v["amount"] - amount)
            diff_money = v["amount"] - amount
            will_amount = v["amount"]
            flag = k
          end
        else
          if diff_money.blank? || (v["amount"] <= amount && diff_money > amount - v["amount"])
            diff_money = v["amount"] - amount
            will_amount = v["amount"]
            flag = k
          end
        end
      end
    end
    [flag, will_amount]
  end

end
