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
      record = rule_084_kssb(record)
      record = rule_084_5_not2(record)
      record = rule_084_to_089(record)
      record = rule_130(record)
      record = rule_222(record)
      record = rule_599_ind1(record)
      record = rule_599_remove(record)
      record = rule_440(record)
      record = rule_830(record)
      record = rule_650_ind2_7fast(record)
      record = rule_650_ind2_mesh(record)
      record = rule_648_ind2_7fast(record)
      record = rule_648_ind2_mesh(record)
      record = rule_651_ind2_7fast(record)
      record = rule_651_ind2_mesh(record)
      record = rule_655_ind2_7fast(record)
      record = rule_655_ind2_mesh(record)
      record = rule_760(record)
      record = rule_762(record)
      record = rule_765(record)
      record = rule_767(record)
      record = rule_770(record)
      record = rule_772(record)
      record = rule_776(record)
      record = rule_779(record)
      record = rule_780(record)
      record = rule_785(record)
      record = rule_787(record)
      record = rule_852(record)
      record = rule_866(record)
      record = rule_976(record)
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
        record.append(MARC::DataField.new('041', ' ', ' ', ['a', lang]))
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

    # Deduplicate 084 on $a when $2 starts with kssb.
    def self.rule_084_kssb(record)
      record = clone(record)

      found_a_fields = []
      highest_kssb_for_a = {}
      idx_to_remove = []

      # Parse through fields, ignoring anything not 084.
      # Store all indexes to remove
      record.fields.each.with_index do |field,idx|
        next if field.tag != "084"
        if field['a'] && field['2'][/^kssb/]
          if found_a_fields.include?(field['a'])
            # If the current field has a lower kssb-value than a previously stored field,
            # mark this one for removal, otherwise remove the previously stored field,
            # and set this as the current highest.
            if field['2'] <= highest_kssb_for_a[field['a']][:value]
              idx_to_remove << idx
            else
              idx_to_remove << highest_kssb_for_a[field['a']][:idx]
              highest_kssb_for_a[field['a']] = {idx: idx, value: field['2']}
            end
            next
          else
            found_a_fields << field['a']
            highest_kssb_for_a[field['a']] = {idx: idx, value: field['2']}
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

    # 084 with $5 and not $2, remove unless $5 contains Ge
    def self.rule_084_5_not2(record)
      record = clone(record)
      record.fields('084').each do |field|
        next if !field['5'] || field['2']
        if field['5'] != "Ge"
          record.remove(field)
        end
      end
      record
    end

    # 084 without $2 or where $2 does not start with kssb, convert to 089
    def self.rule_084_to_089(record)
      record = clone(record)
      record.fields('084').each do |field|
        next if field['2'] && field['2'][/^kssb/]
        record.append(MARC::DataField.new('089', field.indicator1, field.indicator2, *field.subfields))
        record.remove(field)
      end
      record
    end

    # If LEADER7 is s and 130 exists, convert it to 222
    def self.rule_130(record)
      record = clone(record)
      if record.leader[7] == "s"
        field = record['130']
        if field
          record.append(MARC::DataField.new('222', field.indicator1, field.indicator2, *field.subfields))
          record.remove(field)
        end
      end
      record
    end
    
    # If 222$a contains ' - ', replace it with ' / '
    def self.rule_222(record)
      record = clone(record)
      record = replace_dashed_separator(record, '222', 'a')
      record
    end

    # If 599 ind1 and ind2 are blank, and LEADER is s, set ind1 to 1
    def self.rule_599_ind1(record)
      record = clone(record)
      if record.leader[7] == "s"
        record.fields('599').each do |field|
          if field.indicator1 == " " && field.indicator2 == " "
            field.indicator1 = "1"
          end
        end
      end
      record
    end

    # If 599 ind1 and ind2 are blank, remove the field
    def self.rule_599_remove(record)
      record = clone(record)
      record.fields('599').each do |field|
        if field.indicator1 == " " && field.indicator2 == " "
          record.remove(field)
        end
      end
      record
    end

    # If 440$a contains ' - ', replace it with ' / '
    def self.rule_440(record)
      record = clone(record)
      record = replace_dashed_separator(record, '440', 'a')
      record = remove_hyphens_except_issn(record, '440')
      record
    end

    # If 830$a contains ' - ', replace it with ' / '
    def self.rule_830(record)
      record = clone(record)
      record = replace_dashed_separator(record, '830', 'a')
      record
    end

    # If 650$2 contains 'fast' and ind2 is '7', remove it if
    # there exists other 650 fields where ind2 is '0'
    def self.rule_650_ind2_7fast(record)
      record = clone(record)
      record = remove_fast_if_lc(record, '650')
      record
    end

    # If 650 ind2 is '2' (mesh) and ind2 is '0' (LC) is in the same record,
    # keep both, but only mesh if they are duplicates.
    def self.rule_650_ind2_mesh(record)
      record = clone(record)
      record = remove_duplicate_lc_if_mesh(record, '650')
      record
    end

    # If 648$2 contains 'fast' and ind2 is '7', remove it if
    # there exists other 648 fields where ind2 is '0'
    def self.rule_648_ind2_7fast(record)
      record = clone(record)
      record = remove_fast_if_lc(record, '648')
      record
    end

    # If 648 ind2 is '2' (mesh) and ind2 is '0' (LC) is in the same record,
    # keep both, but only mesh if they are duplicates.
    def self.rule_648_ind2_mesh(record)
      record = clone(record)
      record = remove_duplicate_lc_if_mesh(record, '648')
      record
    end

    # If 651$2 contains 'fast' and ind2 is '7', remove it if
    # there exists other 651 fields where ind2 is '0'
    def self.rule_651_ind2_7fast(record)
      record = clone(record)
      record = remove_fast_if_lc(record, '651')
      record
    end

    # If 651 ind2 is '2' (mesh) and ind2 is '0' (LC) is in the same record,
    # keep both, but only mesh if they are duplicates.
    def self.rule_651_ind2_mesh(record)
      record = clone(record)
      record = remove_duplicate_lc_if_mesh(record, '651')
      record
    end

    # If 655$2 contains 'fast' and ind2 is '7', remove it if
    # there exists other 655 fields where ind2 is '0'
    def self.rule_655_ind2_7fast(record)
      record = clone(record)
      record = remove_fast_if_lc(record, '655')
      record
    end

    # If 655 ind2 is '2' (mesh) and ind2 is '0' (LC) is in the same record,
    # keep both, but only mesh if they are duplicates.
    def self.rule_655_ind2_mesh(record)
      record = clone(record)
      record = remove_duplicate_lc_if_mesh(record, '655')
      record
    end

    # Remove hyphens in 760$w 760$x and 760$z if it does not match ISSN
    def self.rule_760(record)
      record = clone(record)
      record = remove_hyphens_except_issn(record, '760')
      record
    end

    # Remove hyphens in 762$w 762$x and 762$z if it does not match ISSN
    def self.rule_762(record)
      record = clone(record)
      record = remove_hyphens_except_issn(record, '762')
      record
    end
    
    # Remove hyphens in 765$w 765$x and 765$z if it does not match ISSN
    def self.rule_765(record)
      record = clone(record)
      record = remove_hyphens_except_issn(record, '765')
      record
    end

    # Remove hyphens in 767$w 767$x and 767$z if it does not match ISSN
    def self.rule_767(record)
      record = clone(record)
      record = remove_hyphens_except_issn(record, '767')
      record
    end

    # Remove hyphens in 770$w 770$x and 770$z if it does not match ISSN
    def self.rule_770(record)
      record = clone(record)
      record = remove_hyphens_except_issn(record, '770')
      record
    end

    # Remove hyphens in 772$w 772$x and 772$z if it does not match ISSN
    def self.rule_772(record)
      record = clone(record)
      record = remove_hyphens_except_issn(record, '772')
      record
    end

    # Remove hyphens in 776$w 776$x and 776$z if it does not match ISSN
    def self.rule_776(record)
      record = clone(record)
      record = remove_hyphens_except_issn(record, '776')
      record
    end

    # Remove hyphens in 779$w 779$x and 779$z if it does not match ISSN
    def self.rule_779(record)
      record = clone(record)
      record = remove_hyphens_except_issn(record, '779')
      record
    end

    # Remove hyphens in 780$w 780$x and 780$z if it does not match ISSN
    def self.rule_780(record)
      record = clone(record)
      record = remove_hyphens_except_issn(record, '780')
      record
    end

    # Remove hyphens in 785$w 785$x and 785$z if it does not match ISSN
    def self.rule_785(record)
      record = clone(record)
      record = remove_hyphens_except_issn(record, '785')
      record
    end

    # Remove hyphens in 787$w 787$x and 787$z if it does not match ISSN
    def self.rule_787(record)
      record = clone(record)
      record = remove_hyphens_except_issn(record, '787')
      record
    end

    # Remove all 852 without \c in $8 if any 852$8 contains \c
    def self.rule_852(record)
      record = clone(record)
      record = clean_8_without_c(record, '852')
      record
    end

    # Remove all 866 without \c in $8 if any 866$8 contains \c
    def self.rule_866(record)
      record = clone(record)
      record = clean_8_without_c(record, '866')
      record
    end

    # Remove 976$a and move $b to $a
    def self.rule_976(record)
      record = clone(record)
      record.fields('976').each do |field|
        subfield_a = field.subfields.find { |sf| sf.code == 'a' }
        if subfield_a
          field.remove(subfield_a)
          field.append(MARC::Subfield.new('a', field['b']))
          field.remove('b')
        end
      end
      record
    end
    
    # Remove all of field tag without \c in $8 if any such field $8 contains \c
    # if it is monograph and if it is considered old (1970-2001)
    def self.clean_8_without_c(record, tag)
      has_c = record.fields(tag).find { |field| field['8'] && field['8'][/\\c/] }
      is_old = false
      # 1970 to 2001
      if record['008'].value[0..1].to_i >= 70 || record['008'].value[0..1].to_i <= 1
        is_old = true
      end
      record.fields(tag).each do |field|
        if is_old && record.leader[7] == 'm' && has_c && field['8'] && !field['8'][/\\c/]
          record.remove(field)
        end
      end
      record
    end
    
    # Remove hyphens in record $w $x and $z if it does not match ISSN
    def self.remove_hyphens_except_issn(record, tag)
      record.fields(tag).each do |field|
        field.subfields.each do |sf|
          if ['w', 'x', 'z'].include?(sf.code)
            # Check if ISSN
            if !sf.value[/^\d\d\d\d-\d\d\d[\dXx]$/]
              sf.value = sf.value.gsub(/-/, '')
            end
          end
        end
      end
      record
    end
    
    # If record$2 contains 'fast' and ind2 is '7', remove it if
    # there exists other records with same tag where ind2 is '0'
    def self.remove_fast_if_lc(record, tag)
      has_ind0 = record.fields(tag).find { |f| f.indicator2 == '0' }
      if has_ind0
        record.fields(tag).each do |field|
          if field.indicator2 == '7' && field['2'] == 'fast'
            record.remove(field)
          end
        end
      end
      record
    end

    # If record ind2 is '2' (mesh) and ind2 is '0' (LC) is in the same record,
    # keep both, but only mesh if they are duplicates.
    def self.remove_duplicate_lc_if_mesh(record, tag)
      mesh_fields = {}
      record.fields(tag).each do |field|
        if field.indicator2 == '2'
          mesh_data = field.subfields.map { |sf| "$#{sf.code} #{sf.value}"}.join(" ")
          mesh_fields[mesh_data] = field
        end
      end
      record.fields(tag).each do |field|
        if field.indicator2 == '0'
          lc_data = field.subfields.map { |sf| "$#{sf.code} #{sf.value}"}.join(" ")
          # Check if there is a mesh term for this already
          if mesh_fields[lc_data]
            record.remove(field)
          end
        end
      end
      record
    end
    
    # Replace ' - ' with ' / ' in specified field and subfield
    def self.replace_dashed_separator(record, tag, subfield_code)
      if record[tag] && record[tag][subfield_code] && record[tag][subfield_code][/ - /]
        subfield = record[tag].subfields.find_all { |sf| sf.code == subfield_code}.first
        subfield.value = record[tag][subfield_code].gsub(/ - /, ' / ')
      end
      record
    end
  end
end
