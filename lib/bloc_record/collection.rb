module BlocRecord
  class Collection < Array
    def update_all(updates)
      ids = self.map(&:id)
      self.any? ? self.first.class.update(ids, updates) : false
    end

    def take
      ids = self.map(&:id)[0]
      puts self.any?
      self.any? ? self.first.class.where(id: ids) : false
    end

    def where(attributes)
      ids = self.map(&:id)
      self.any? ? self.first.class.where(attributes) : false
    end

    def not(args)
      case args
      when String
        expression = args.first
      when Hash
        expression_hash = BlocRecord::Utility.convert_keys(args)
        expression = expression_hash.map {|key, value| "#{key}!=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ")
      end
      self.any? ? self.first.class.where(expression) : false
    end

  end
end
