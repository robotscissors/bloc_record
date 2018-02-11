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

  def find_each(start: 1, batch_size: 1000)
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE id = #{start}
      LIMIT #{batch_size}
      SQL
    entries = rows_to_array(rows)
    entries.each{ |e| yield e }
  end


  def find_batch(start, batch_size)
    #find one batch
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE id = #{start}
      LIMIT #{batch_size}
      SQL
    rows_to_array(rows)
  end

  def find_in_batches(start, batch_size)
    #find out how many records are total
    row = connection.execute <<-SQL
      SELECT count(id) FROM #{table};
    SQL
    max = row[0][0]
    batch_num = 0;
    while start < max do
      # find batch
      entries = find_batch(start, batch_size)
      entries.each{ |e| yield e }
      #increment batch_start, batch_num
      start += batch_size
      batch_num += 1
    end
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


  def where(*args)
    if args.count > 1
      expression = args.shift
      params = args
    else
        case args.first
        when String
          expression = args.first
        when Hash
          expression_hash = BlocRecord::Utility.convert_keys(args.first)
          expression = expression_hash.map {|key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ")
        end
    end

    sql = <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE #{expression};
    SQL

    rows = connection.execute(sql, params)
    rows_to_array(rows)
  end

  def order(*args)
    all_args=[]
    if args.length>0
      args.each do |arg|
        case arg
        when Symbol #a symbol only
          all_args << arg.to_s + " ASC"
        when Hash # a hash
          arg.each{|k,v| all_args << "#{k} #{v}"}
        when String # a string
          all_args << arg
        end
      end
      order = all_args.join(', ')

      rows = connection.execute <<-SQL
        SELECT * FROM #{table}
        ORDER BY #{order};
      SQL
    else
       # there are no parameters
       rows = connection.execute <<-SQL
         SELECT * FROM #{table};
       SQL
    end
    rows_to_array(rows)
  end

  def join(*args)
    if args.count > 1
      joins = args.map { |arg| "INNER JOIN #{arg} ON #{arg}.#{table}_id = #{table}.id"}.join(" ")
      rows = connection.execute <<-SQL
        SELECT * FROM #{table} #{joins}
      SQL
    else
      case args.first
      when String
        rows = connection.execute <<-SQL
          SELECT * FROM #{table} #{BlocRecord::Utility.sql_strings(args.first)};
        SQL
      when Symbol
        rows = connection.execute <<-SQL
          SELECT * FROM #{table}
          INNER JOIN #{args.first} ON #{args.first}.#{table}_id = #{table}.id
        SQL
      when Hash
        table1 = args.first.keys[0].to_s.slice!(0..-2)
        table2 = args.first.values[0].to_s
        rows = connection.execute <<-SQL
          SELECT * FROM #{table}
          INNER JOIN #{table1} ON #{table1}.#{table}_id = #{table}_id
          INNER JOIN #{table2} ON #{table2}.#{table1}_id = #{table1}_id
        SQL
      end
    end

    rows_to_array(rows)
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
