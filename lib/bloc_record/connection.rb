require 'sqlite3'
require 'pg'

module Connection
  def connection
    if @database_platform === 'pg'
      @connection ||= PG::Database.new(BlocRecord.database_filename)
    else
      @connection ||= SQLite3::Database.new(BlocRecord.database_filename)
    end
  end
end
