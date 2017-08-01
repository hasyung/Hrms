# == Schema Information
#
# Table name: department_change_logs
#
#  id            :integer          not null, primary key
#  title         :string(255)
#  oa_file_no    :string(255)
#  step_desc     :text(65535)
#  dep_name      :string(255)
#  department_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class DepartmentChangeLog < ActiveRecord::Base
  scope :latest_version, -> { order('id DESC') }

  belongs_to :department
  belongs_to :employee

  validates_presence_of :title, :oa_file_no, :department_id

  def self.next_version
    current_version = latest_version
    current_version.empty? ? 1 : (current_version.first.id + 1)
  end
end
