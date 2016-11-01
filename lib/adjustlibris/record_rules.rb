class AdjustLibris
  class RecordRules
    # Apply in turn each and every rule, and return a record in the end.
    def self.apply(record)
      record = rule_041(record)
      record = rule_020(record)
      record = rule_035_9(record)
      record = rule_035_9_to_a(record)
      record = rule_035_5(record)
      record = rule_084_5_2(record)
      record
    end

    def self.clone(record)
      MARC::Record.new_from_marc(record.to_marc)
    end
    
    # If 041 does not exist, copy 008/35-37 to 041$a,
    #   unless 008/35-37 is ["und", "xxx", "mul"]
    def self.rule_041(record)
      record = clone(record)
      f008 = record["008"]
      if !f008
        raise StandardError, "ControlField 008 missing"
      end
      lang = f008.value[35..37]
      if !["und", "xxx", "mul"].include?(lang) && !record["041"]
        record.append(MARC::DataField.new('041', '', '', ['a', lang]))
      end
      record
    end

    # Remove any '-' from any 020$a and 020$z
    def self.rule_020(record)
      record = clone(record)
      record.fields('020').each do |field|
        sub_a = field.find_all { |subfield| subfield.code == 'a'}
        sub_z = field.find_all { |subfield| subfield.code == 'z'}

        subs = sub_a + sub_z
        
        if subs
          subs.each do |subfield|
            subfield.value = subfield.value.gsub(/-/,'')
          end
        end
      end
      record
    end

    # Deduplicate 030 on $a
    def self.rule_030(record)
      record = clone(record)

      found_a_fields = []
      idx_to_remove = []

      # Parse through fields, ignoring anything not 030.
      # Store all indexes to remove
      record.fields.each.with_index do |field,idx|
        next if field.tag != "030"
        if field['a']
          if found_a_fields.include?(field['a'])
            idx_to_remove << idx
            next
          else
            found_a_fields << field['a']
          end
        end
      end

      # Remove all indexes in reverse order (highest first)
      # so that index numbering isn't thrown off
      idx_to_remove.reverse.each do |idx|
        record.remove_at(idx)
      end
      record
    end

    # If 035$9 contains exactly 8 characters, insert a dash in the middle.
    def self.rule_035_9(record)
      record = clone(record)
      record.fields('035').each do |field|
        next if !field['9']
        if field['9'].size == 8
          subfield = field.subfields.find_all { |sf| sf.code == '9' }.first
          subfield.value = field['9'][0..3] + '-' + field['9'][4..7]
        end
      end
      record
    end

    # If 035$9 exists, move it to 035$a.
    def self.rule_035_9_to_a(record)
      record = clone(record)
      record.fields('035').each do |field|
        next if !field['9']
        field.append(MARC::Subfield.new('a', field['9']))
        field.remove('9')
      end
      record
    end

    # If 035$5 exists, remove the entire 035 field.
    def self.rule_035_5(record)
      record = clone(record)
      record.fields('035').each do |field|
        if field['5']
          record.remove(field)
        end
      end
      record
    end

    # Remove all 084 where neither $5 nor $2 exists.
    def self.rule_084_5_2(record)
      record = clone(record)
      record.fields('084').each do |field|
        next if field['5'] || field['2']
        record.remove(field)
      end
      record
    end
  end
end
