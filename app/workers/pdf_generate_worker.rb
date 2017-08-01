require 'htmltoword'

class PdfGenerateWorker
  include Sidekiq::Worker

  def perform(file_path, templ)
    Htmltoword::Document.create_and_save(templ, file_path)
  end
end
