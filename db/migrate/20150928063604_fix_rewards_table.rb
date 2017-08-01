class FixRewardsTable < ActiveRecord::Migration
  def change
    remove_column :rewards, :in_out_bonus
    remove_column :rewards, :best_goods
    remove_column :rewards, :best_plan
    remove_column :rewards, :bonus_2

    add_column :rewards, :insurance_proxy, :decimal, precision: 10, scale: 2, index: true, comment: '电子航意险代理提成奖'
    add_column :rewards, :cabin_grow_up, :decimal, precision: 10, scale: 2, index: true, comment: '客舱升舱提成奖'
    add_column :rewards, :full_sale_promotion, :decimal, precision: 10, scale: 2, index: true, comment: '全员促销奖'
    add_column :rewards, :article_fee, :decimal, precision: 10, scale: 2, index: true, comment: '四川航空报稿费'
    add_column :rewards, :all_right_fly, :decimal, precision: 10, scale: 2, index: true, comment: '无差错飞行中队奖'
    add_column :rewards, :year_composite_bonus, :decimal, precision: 10, scale: 2, index: true, comment: '年度综治奖'
    add_column :rewards, :move_perfect, :decimal, precision: 10, scale: 2, index: true, comment: '运兵先进奖'
    add_column :rewards, :security_special, :decimal, precision: 10, scale: 2, index: true, comment: '航空安全特殊贡献奖'
    add_column :rewards, :dep_security_undertake, :decimal, precision: 10, scale: 2, index: true, comment: '部门安全管理目标承包奖'
    add_column :rewards, :fly_star, :decimal, precision: 10, scale: 2, index: true, comment: '飞行安全星级奖'
    add_column :rewards, :year_all_right_fly, :decimal, precision: 10, scale: 2, index: true, comment: '年度无差错机务维修中队奖'
    add_column :rewards, :network_connect, :decimal, precision: 10, scale: 2,index: true, comment: '网络联程奖'
    add_column :rewards, :quarter_fee, :decimal, precision: 10, scale: 2, index: true, comment: '季度奖'
    add_column :rewards, :earnings_fee, :decimal, precision: 10, scale: 2, index: true, comment: '收益奖励金'
    add_column :rewards, :add_garnishee, :decimal, precision: 10, scale: 2, comment: '补扣发'
    add_column :rewards, :remark, :string, comment: '备注'
  end
end
