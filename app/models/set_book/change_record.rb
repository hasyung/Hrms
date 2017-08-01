class SetBook::ChangeRecord < ActiveRecord::Base
  belongs_to :employee
end
