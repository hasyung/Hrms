class AddConfigFieldsToDinnerPersonSetups < ActiveRecord::Migration
  def change
    add_column :dinner_person_setups, :form_data, :text, comment: '餐费的原始配置'
    add_column :dinner_person_setups, :is_config_modified, :boolean, default: false, index: true, comment: '餐费个人设置是否被独立修改过'
  end
end
