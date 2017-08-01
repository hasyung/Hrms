# == Schema Information
#
# Table name: snapshots
#
#  id         :integer          not null, primary key
#  model      :string(255)
#  version    :integer          default("0")
#  data       :text(65535)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_snapshots_on_model    (model)
#  index_snapshots_on_version  (version)
#

class Snapshot < ActiveRecord::Base
  include Departmentable

  serialize :data, Hash

  scope :departments, -> { where(model: 'department') }
  scope :department_grades, -> { where(model: 'departmentgrade') }
  scope :model_with, -> (model) {where(model: model)}
  scope :version, -> (version) {where(version: version)}

  validates_presence_of :model, :version

  def self.search_by(condition = {})
    condition.inject(self) do |result, (key, val)|
      result = result.where("data like ?", "---\n%#{key}: #{val}\n%")
      result
    end
  end

  def grade_id
    self.data["grade_id"]
  end

  def childrens
    parent_id = "---\n%parent_id: #{self.data["id"]}\n%"

    Snapshot.version(self.version).where('data like ?', parent_id)
  end

  def childrens_count
    self.data["childrens_count"]
  end

  def name
    self.data["name"]
  end

  def depth
    self.data["depth"]
  end
end
