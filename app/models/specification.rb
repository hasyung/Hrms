require 'htmltoword'
# == Schema Information
#
# Table name: specifications
#
#  id                   :integer          not null, primary key
#  duty                 :text(65535)
#  personnel_permission :text(65535)
#  financial_permission :text(65535)
#  business_permission  :text(65535)
#  superior             :text(65535)
#  underling            :text(65535)
#  internal_relation    :text(65535)
#  external_relation    :text(65535)
#  qualification        :text(65535)
#  position_id          :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
# Indexes
#
#  index_specifications_on_position_id  (position_id)
#

class Specification < ActiveRecord::Base
  # validates_presence_of :duty, :permission, :relation #, :qualification, :position_id
  belongs_to :position

  before_destroy :delete_pdf
  after_save :manual_save_pdf, unless: -> (pec) { pec.position && pec.position.is_delete == true}

  audited associated_with: :position, except: [ :position_id ]

  def pdf_dir
    "#{Rails.root}/public/export/pdf/specifications/"
  end

  def pdf_filename
    position = Position.unscoped{self.position}
    "#{position.name.gsub('/', '&')}描述书(#{position.department.full_name}-#{self.id}).docx"
  end

  def pdf_path
    pdf_dir + pdf_filename
    # pdf_dir + "hello.pdf"
  end

  def manual_save_pdf
    @specification = self
    @position = @specification.position
    html = ErbService.new("#{Rails.root}/app/views/api/specifications/show.html.erb", binding).to_html

    FileUtils.mkdir_p(self.pdf_dir) unless File.directory?(self.pdf_dir)
    Htmltoword::Document.create_and_save(html, self.pdf_path)
  end

  private
  def delete_pdf
    FileUtils.rm(self.pdf_path) if FileTest::exist?(self.pdf_path)
  end

  def write_pdf
    @specification = self
    @position = @specification.position
    html = ErbService.new("#{Rails.root}/app/views/api/specifications/show.html.erb", binding).to_html
    FileUtils.mkdir_p(self.pdf_dir) unless File.directory?(self.pdf_dir)

    PdfGenerateWorker.perform_async(self.pdf_path, html)
  end
end
