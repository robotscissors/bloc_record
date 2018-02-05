require 'sqlite3'

module Selection
  def find(*ids)
    ids.each do |items|
      return unless check_for_valid_id(items)
    end
    begin
      if ids.length == 1
        find_one(ids.first)
      else
        rows = connection.execute <<-SQL
          SELECT #{columns.join ","} FROM #{table}
          WHERE id IN (#{ids.join(",")});
        SQL
        rows_to_array(rows)
      end
    rescue
      puts "There is a problem with the selection"
    end
  end

  def find_one(id)
    return unless check_for_valid_id(id)
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE id = #{id};
    SQL
    init_object_from_row(row)
  end

  def find_by(attribute, value)
   row = connection.get_first_row <<-SQL
     SELECT #{columns.join ","} FROM #{table}
     WHERE #{attribute} = #{BlocRecord::Utility.sql_strings(value)};
   SQL
   puts "This is the value: #{value}"
   init_object_from_row(row)
  end

  def find_each(*args)
    if args.length > 0
      #there are arguments - parse key and values
      arguments = args[0].to_h
      start = arguments[:start]
      batch_size = arguments[:batch_size]
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        WHERE id = #{start}
        LIMIT #{batch_size}
        SQL
      entries = rows_to_array(rows)
      entries.each{ |e| yield e }
    else
      #get all items
      entries = self.all
      entries.each{ |e| yield e }
    end
  end

  def find_in_batches(*args)
    arguments = args[0].to_h
    start = arguments[:start]
    batch_size = arguments[:batch_size]
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE id = #{start}
      LIMIT #{batch_size}
      SQL
  end

  def take(num=1)
    return unless check_for_valid_num(num)
    if num > 1
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        ORDER BY random()
        LIMIT #{num};
      SQL

      rows_to_array(rows)
    else
      take_one
    end
  end

  def take_one
   row = connection.get_first_row <<-SQL
     SELECT #{columns.join ","} FROM #{table}
     ORDER BY random()
     LIMIT 1;
   SQL

   init_object_from_row(row)
  end

  def first
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id ASC LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def last
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id DESC LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def all
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table};
    SQL

    rows_to_array(rows)
  end

  def method_missing(m, *args, &block)
      value = args[0]
      case m.to_s
        when 'find_by_name'
          self.find_by(:name, value)
        when 'find_by_phone'
          self.find_by(:phone_number, value)
        else
          puts "There is no method, you have an error"
      end
  end


  private
  def init_object_from_row(row)
   if row
     data = Hash[columns.zip(row)]
     new(data)
   end
  end

  def rows_to_array(rows)
    rows.map { |row| new(Hash[columns.zip(row)]) }
  end

  def check_for_valid_id(id)
    if id<0
      puts "Invalid ID - ID must be greater than or equal to zero"
      return false
    end
    true
  end

  def check_for_valid_num(num)
    if !num.is_a? Numeric
      puts "Invalid value - this must contain a number"
      return false
    end
    true
  end

end
