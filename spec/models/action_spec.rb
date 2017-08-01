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

require 'rails_helper'

RSpec.describe Action, :type => :model do
  before(:each) do
    @root_department = Department.create
    @hash = {
      model: 'department',
      category: 'create!',
      data: {parent_id: @root_department.id, name: 'second root department'},
      description: 'create second department'
    }
  end

  context "should execute action with create successfully" do
    #it "with persist = false" do
      #@action = create(:action, attributes: @hash)
      #@departments = Department.all.to_a
      #@departments = Action.batch_execute(Department, [@action])
      #expect(@departments.size).to equal(2)
      #puts "---- with persist = false ---- "
      #puts @departments
    #end

    #it "with persist = true" do
      #@action = Action.create!(@hash)
      #@departments = Department.all.to_a
      #@departments = Action.batch_execute(Department, [@action], true)
      #expect(@departments.size).to equal(2)
      #puts "---- with persist = true ---- "
      #puts @departments
    #end
  end

  context "should execute action with update successfully" do
    #TODO need implements test
  end

  context "should execute action with destroy successfully" do
    #TODO need implements test
  end
end
