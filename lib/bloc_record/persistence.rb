require 'sqlite3'
require 'pg'
require 'bloc_record/schema'

module Persistence
  def self.included(base)
    base.extend(ClassMethods)
  end

  def save
    self.save! rescue false
  end


  def save!
    unless self.id
      self.id = self.class.create(BlocRecord::Utility.instance_variables_to_hash(self)).id
      BlocRecord::Utility.reload_obj(self)
      return true
    end

   fields = self.class.attributes.map { |col| "#{col}=#{BlocRecord::Utility.sql_strings(self.instance_variable_get("@#{col}"))}" }.join(",")

   self.class.connection.execute <<-SQL
     UPDATE #{self.class.table}
     SET #{fields}
     WHERE id = #{self.id};
   SQL

   true
  end

  def update_attribute(attribute, value)
   self.class.update(self.id, { attribute => value })
  end

  def update_attributes(updates)
   self.class.update(self.id, updates)
  end

  def destroy
    self.class.destroy(self.id)
  end

  module ClassMethods
    def update_all(updates)
      update(nil, updates)
    end

    def destroy(*id)
      puts "#{id} - length"
     if id.length > 1
       where_clause = "WHERE id IN (#{id.join(",")});"
     else
       case id.first
       when Array
         where_clause = "WHERE id IN (#{id.join(",")});"
       else
         where_clause = "WHERE id = #{id.first};"
       end
     end
     puts "DELETE FROM #{table} #{where_clause}"
       connection.execute <<-SQL
         DELETE FROM #{table} #{where_clause}
       SQL
     true
    end

    def destroy_all(*args)
      if args.length > 1
          conditions = args.first.gsub(/\?/,"'"+args[1]+"'")
          connection.execute <<-SQL
          DELETE FROM #{table}
          WHERE #{conditions};
        SQL
      else
        case args.first
        when String
          conditions = args.first
          connection.execute <<-SQL
            DELETE FROM #{table}
            WHERE #{conditions};
          SQL
        when HASH && args.first && !args.first.empty?
            conditions_hash = BlocRecord::Utility.convert_keys(args.first)
            conditions = conditions_hash.map {|key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ")
            connection.execute <<-SQL
              DELETE FROM #{table}
              WHERE #{conditions};
            SQL
        else
          connection.execute <<-SQL
            DELETE FROM #{table}
          SQL
        end
      end
      true
    end

    def create(attrs)
      attrs = BlocRecord::Utility.convert_keys(attrs)
      attrs.delete "id"
      vals = attributes.map { |key| BlocRecord::Utility.sql_strings(attrs[key]) }

      connection.execute <<-SQL
        INSERT INTO #{table} (#{attributes.join ","})
        VALUES (#{vals.join ","});
      SQL

      data = Hash[attributes.zip attrs.values]
      data["id"] = connection.execute("SELECT last_insert_rowid();")[0][0]
      new(data)
    end

    def update(ids, updates)
      #check to see if updates is an array or hash
      if updates.class == Array #then mulitple updates
        id = 0
        updates.each do |update|
          new_set = update.map { |key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}" }[0]
          connection.execute <<-SQL
            UPDATE #{table}
            SET #{new_set} WHERE id = #{ids[id]}
          SQL
          id += 1
        end
      else
        updates = BlocRecord::Utility.convert_keys(updates)
        updates.delete "id"
        updates_array = updates.map { |key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}" }

        if ids.class == Fixnum
          where_clause = "WHERE id = #{ids};"
        elsif ids.class == Array
          where_clause = ids.empty? ? ";" : "WHERE id IN (#{ids.join(",")});"
        else
          where_clause = ";"
        end

        connection.execute <<-SQL
          UPDATE #{table}
          SET #{updates_array * ","} #{where_clause}
        SQL
      end
      true
    end
  end

  def method_missing(m, *args, &block)
      value = args[0]

      case m.to_s
        when /^update_/
          attribute_name = m.slice(7,m.length).to_sym
          self.update_attribute(attribute_name, value)
        else
          puts "There is no method, you have an error"
      end
  end
end
