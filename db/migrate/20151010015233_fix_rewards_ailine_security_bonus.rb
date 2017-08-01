class FixRewardsAilineSecurityBonus < ActiveRecord::Migration
  def change
    rename_column :rewards, :ailine_security_bonus, :airline_security_bonus
    rename_column :reward_records, :ailine_security_bonus, :airline_security_bonus
  end
end
