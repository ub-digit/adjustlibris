class AdjustLibris
  class RecordRules
    # Apply in turn each and every rule, and return a record in the end.
    def self.apply(record)
      record = rule_041(record)
      record
    end

    # If 041 does not exist, copy 008/35-37 to 041$a,
    #   unless 008/35-37 is ["und", "xxx", "mul"]
    def self.rule_041(record)
      f008 = record["008"]
      if !f008
        raise StandardError, "ControlField 008 missing"
      end
      lang = f008.value[35..37]
      if !["und", "xxx", "mul"].include?(lang)
        record.append(MARC::DataField.new('041', '', '', ['a', lang]))
      end
      record
    end
  end
end
