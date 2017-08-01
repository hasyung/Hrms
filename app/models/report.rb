class Report < ActiveRecord::Base
  belongs_to :employee

  serialize :checker, Array

  has_many :attachments, as: :attachmentable, dependent: :destroy
end
