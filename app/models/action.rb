# == Schema Information
#
# Table name: actions
#
#  id          :integer          not null, primary key
#  model       :string(255)
#  category    :string(255)
#  description :string(255)
#  data        :text(65535)
#  employee_id :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_actions_on_category  (category)
#  index_actions_on_model     (model)
#

class Action < ActiveRecord::Base
  serialize :data, Hash

  validates_presence_of :model, :category, :data

  belongs_to :employee

  scope :model, ->(model) {where(model: model)}
  scope :category_with, ->(category) { where(category: category) }

  def self.find_by_model_and_id(model, id)
    record = self.batch_execute(model, self.all.to_a).index_by(&:id)[id.to_i]
    record ? record : (raise ActiveRecord::RecordNotFound)
  end

  def self.search_by(condition = {})
    condition.inject(self) do |result, (key, val)|
      result = result.where("data like ?", "---\n%#{key}: #{val}\n%")
      result
    end
  end

  def self.batch_execute(model, actions, persist = false)
    records = model.all.to_a

    actions.each do |action|
      records = action.execute_action(model, records, persist)
    end

    records
  end

  def localize_category
    #暂时放到这里
    {"create!" => "创建", "update!" => "修改", "destroy!" => "删除", "transfer!" => "划转"}[self.category]
  end

  def execute_action(model, records, persist = false)
    if persist
      excute_for_persist(model)
    else
      excute_for_build(records)
    end
  end

  private
  def excute_for_persist(model)
    case self.category
    when 'create!'
      item = model.create(self.data.delete_if{|k|k=='id'})
      item.set_sort_no.save!
    when 'update!'
      model.find(self.data["id"]).update!(self.data)
    when 'destroy!'
      model.find(self.data["id"]).destroy
    when 'transfer!'
      #部门划转处理步骤:
      item = model.find(self.data["id"])
      # 1. 更新部门的编号
      # item.set_serial_number_and_depth(true, model.find(self.data['parent_id']))
      item.update(self.data.delete_if{|key|key == 'id' or key == 'childrens_index'})
      # 2. 更新部门的信息
      #item.update!(self.data.delete_if{|key|key == 'serial_number' or key == 'depth'})
      # 3. 更新部门sort_no
      item.set_sort_no(model.find(self.data['parent_id'])).save!
    else
      raise "Invalid category for action with #{self.serializable_hash}"
    end
  end

  def excute_for_build(records)
    category = self.category

    if category == 'create!'
      record = self.model.classify.constantize.new(self.data)
      records << record
    elsif (['update!', 'destroy!', 'transfer!'].include?(category))
      hash = records.index_by(&:id)
      id = self.data.delete("id").to_i
      record = hash[id]

      if record.new_record? && category == 'destroy!'
        records.delete(record)
      else
        self.data.each {|attr, value| record.send("#{attr}=", value)}
      end
    else
      raise "Invalid category for action with #{self.serializable_hash}"
    end

    records
  end
end
