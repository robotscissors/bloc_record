module BlocRecord
  def self.connect_to(filename, platform)
    @database_filename = filename
    @database_platform = platform.to_s
  end

  def self.database_filename
    @database_filename
  end
end
