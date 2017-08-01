class Admin::BackupsController < AdminController
  def index
    dir = "/var/www/backup/*.tar.gz"
    dir = "/Users/Ray/Downloads/*" if Rails.env.development?
    @files = []

    Dir.glob(dir).each do |file|
      hash = {filename: File.basename(file), size: File.size(file), mtime: File.mtime(file)}
      @files << hash
    end

    @files.sort_by!{|x|x[:mtime]}.reverse!
  end

  def download
    dir = "/var/www/backup/"
    dir = "/Users/Ray/Downloads/" if Rails.env.development?
    filename = File.join(dir, params[:filename])

    if File.exist?(filename)
      send_file filename, :type=>"application/zip"
    else
      flash[:notice] = "文件不存在"
      redirect_to admin_backups_path
    end
  end

end
