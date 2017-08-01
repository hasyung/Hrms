# == Schema Information
#
# Table name: primary_keys
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  model      :string(255)
#  max_id     :integer          default("0")
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_primary_keys_on_name  (name)
#

class PrimaryKey < ActiveRecord::Base

  def self.get_autoincrement_id(model, is_increment = true)
    pk = where(model: model).first
    klass = model.classify.constantize

    pk = ::PrimaryKey.create(name: model, model: model) unless pk
    pk.update_attribute(:max_id, klass.order('id DESC').first.try(:id) || 0) if pk.max_id == 0
    pk.increment!(:max_id) if is_increment

    pk.max_id
  end

end
