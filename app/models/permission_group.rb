class PermissionGroup < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name

  serialize :permission_ids, Array
end
