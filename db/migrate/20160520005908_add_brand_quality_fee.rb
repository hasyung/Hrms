class AddBrandQualityFee < ActiveRecord::Migration
  def change
    add_column :department_salaries, :brand_quality_fee, :decimal, precision: 10, scale: 2, index: true, comment: "品牌质量考核奖"
    add_column :rewards, :brand_quality_fee, :decimal, precision: 10, scale: 2, index: true, comment: "品牌质量考核奖"
    add_column :reward_records, :brand_quality_fee, :decimal, precision: 10, scale: 2, index: true, comment: "品牌质量考核奖"
  end
end
