class Object
  def send_methods(*args)
    args.first.split('.').inject(self) do |results, method|
      begin
        results = results.send(method)
      rescue NoMethodError
        next
      end
      results
    end
  end
end
