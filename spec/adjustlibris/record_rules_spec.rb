describe "AdjustLibris::RecordRules" do
  
  context "Rules" do
    context "rule_041" do
      before :each do
        @record_without_041 = MARC::Reader.new("spec/data/rule_041-without_041.mrc").first
        @record_with_041 = MARC::Reader.new("spec/data/rule_041-with_041.mrc").first
        @record_wrong_lang = MARC::Reader.new("spec/data/rule_041-wrong_lang.mrc").first
      end
      
      it "should add 041$a when it does not exist" do
        new_record = AdjustLibris::RecordRules.rule_041(@record_without_041)
        expect(new_record["041"]).to be_kind_of(MARC::DataField)
        expect(new_record["041"]["a"]).to eq("eng")
      end

      it "should not touch 041$a when it already exists" do
        new_record = AdjustLibris::RecordRules.rule_041(@record_with_041)
        expect(new_record.fields("041").count).to eq(@record_with_041.fields("041").count)
        expect(new_record["041"]).to be_kind_of(MARC::DataField)
        expect(new_record["041"]["a"]).to eq(@record_with_041["041"]["a"])
      end

      it "should not create 041$a if 008/35-37 is und, xxx or mul" do
        new_record = AdjustLibris::RecordRules.rule_041(@record_wrong_lang)
        expect(new_record["041"]).to_not be_kind_of(MARC::DataField)
      end
    end

    context "rule_020" do
      before :each do
        @record_020z_with_dash = MARC::Reader.new("spec/data/rule_020-z_with_dash.mrc").first
        @record_020a_with_dash = MARC::Reader.new("spec/data/rule_020-a_with_dash.mrc").first
      end
      
      it "should remove all dashes from 020$z" do
        new_record = AdjustLibris::RecordRules.rule_020(@record_020z_with_dash)
        expect(new_record["020"]).to be_kind_of(MARC::DataField)
        expect(new_record["020"]["z"]).to eq("9339344444444")
      end

      it "should remove all dashes from 020$a" do
        new_record = AdjustLibris::RecordRules.rule_020(@record_020a_with_dash)
        expect(new_record["020"]).to be_kind_of(MARC::DataField)
        expect(new_record["020"]["a"]).to eq("9339344444444")
      end
    end

    context "rule_030" do
      before :each do
        @record_030 = MARC::Reader.new("spec/data/rule_030.mrc").first
      end
      
      it "should deduplicate 030 based on $a" do
        new_record = AdjustLibris::RecordRules.rule_030(@record_030)
        fields = new_record.fields('030')
        expect(fields.count).to eq(5)
        expect(fields[0]).to be_kind_of(MARC::DataField)
        expect(fields[0]['a']).to eq("CODEN1") 
        expect(fields[0]['z']).to be_nil
        expect(fields[1]).to be_kind_of(MARC::DataField)
        expect(fields[1]['z']).to eq("CODENINVAL") 
        expect(fields[1]['a']).to be_nil
        expect(fields[2]).to be_kind_of(MARC::DataField)
        expect(fields[2]['z']).to eq("CODENINVAL2") 
        expect(fields[2]['a']).to be_nil
        expect(fields[3]).to be_kind_of(MARC::DataField)
        expect(fields[3]['a']).to eq("CODEN2")
        expect(fields[3]['z']).to eq("CODENINVAL") 
        expect(fields[4]).to be_kind_of(MARC::DataField)
        expect(fields[4]['a']).to eq("CODEN3")
        expect(fields[4]['z']).to eq("CODENINVAL")
      end
    end

    context "rule_035" do
      before :each do
        @record_035_with_sub9_8chars = MARC::Reader.new("spec/data/rule_035-with_sub9_8chars.mrc").first
        @record_035_with_sub9_not_8chars = MARC::Reader.new("spec/data/rule_035-with_sub9_not_8chars.mrc").first
        @record_035_with_sub5 = MARC::Reader.new("spec/data/rule_035-with_sub5.mrc").first
      end

      it "should insert a dash in 035$9 if length is exactly 8 (issn)" do
        new_record = AdjustLibris::RecordRules.rule_035_9(@record_035_with_sub9_8chars)
        expect(new_record['035']['9']).to eq("1111-2345")
      end
      
      it "should not insert a dash in 035$9 if length is other than 8 (issn)" do
        new_record = AdjustLibris::RecordRules.rule_035_9(@record_035_with_sub9_not_8chars)
        expect(new_record['035']['9']).to eq("991234567")
      end
      
      it "should move 035$9 to 035$a" do
        new_record = AdjustLibris::RecordRules.rule_035_9_to_a(@record_035_with_sub9_not_8chars)
        expect(new_record['035']['9']).to be_nil
        expect(new_record['035']['a']).to eq("991234567")
      end

      it "should remove a 035 field if it has a $5" do
        new_record = AdjustLibris::RecordRules.rule_035_5(@record_035_with_sub5)
        expect(new_record['035']).to be_nil
      end
    end

    context "rule_082" do
      before :each do
        @record_082 = MARC::Reader.new("spec/data/rule_082.mrc").first
      end

      it "should deduplicate 082" do
        old_fields = @record_082.fields('082')
        expect(old_fields.count).to eq(2)
        new_record = AdjustLibris::RecordRules.rule_082(@record_082)
        fields = new_record.fields('082')
        expect(fields.count).to eq(1)
      end
    end

    context "rule_084" do
      before :each do
        @record_084_without_sub5_2 = MARC::Reader.new("spec/data/rule_084-without_sub5_2.mrc").first
        @record_084_with_multiple_kssb = MARC::Reader.new("spec/data/rule_084-with_multiple_kssb.mrc").first
        @record_084_with_sub5_not2 = MARC::Reader.new("spec/data/rule_084-with_sub5_not2.mrc").first
        @record_084_with_sub5_not2_to_089 = MARC::Reader.new("spec/data/rule_084-with_sub5_not2_to_089.mrc").first
      end

      it "should remove field if no $5 or $2 is present" do
        new_record = AdjustLibris::RecordRules.rule_084_5_2(@record_084_without_sub5_2)
        expect(new_record['084']).to be_nil
      end

      it "should deduplicate 084 based on $a when $2 starts with kssb" do
        new_record = AdjustLibris::RecordRules.rule_084_kssb(@record_084_with_multiple_kssb)
        fields = new_record.fields('084')
        expect(fields.count).to eq(3)
        expect(fields[0]).to be_kind_of(MARC::DataField)
        expect(fields[0]['a']).to eq("F:do") 
        expect(fields[0]['2']).to eq("kssb/8 (machine generated)")
        expect(fields[1]).to be_kind_of(MARC::DataField)
        expect(fields[1]['a']).to eq("F:fno") 
        expect(fields[1]['2']).to eq("kssb/9")
        expect(fields[2]).to be_kind_of(MARC::DataField)
        expect(fields[2]['a']).to eq("F:other") 
        expect(fields[2]['2']).to eq("not same")
      end

      it "should remove field if $5 is present, but not $2 except if $5 contains Ge" do
        new_record = AdjustLibris::RecordRules.rule_084_5_not2(@record_084_with_sub5_not2)
        fields = new_record.fields('084')
        expect(fields.count).to eq(2)
        expect(fields[0]).to be_kind_of(MARC::DataField)
        expect(fields[0]['a']).to eq("F:do") 
        expect(fields[0]['5']).to be_nil
        expect(fields[1]).to be_kind_of(MARC::DataField)
        expect(fields[1]['a']).to eq("F:other") 
        expect(fields[1]['5']).to eq("Ge")
      end

      it "should convert field to 089 if $2 is not present or if $2 does not start with kssb" do
        new_record = AdjustLibris::RecordRules.rule_084_to_089(@record_084_with_sub5_not2_to_089)

        fields = new_record.fields('084')
        expect(fields.count).to eq(1)
        expect(fields[0]).to be_kind_of(MARC::DataField)
        expect(fields[0]['a']).to eq("F:do") 
        expect(fields[0]['2']).to_not be_nil

        fields = new_record.fields('089')
        expect(fields.count).to eq(1)
        expect(fields[0]).to be_kind_of(MARC::DataField)
        expect(fields[0]['a']).to eq("F:other") 
        expect(fields[0]['5']).to eq("Ge")
      end
    end      

    context "rule_130" do
      before :each do
        @record_130_s = MARC::Reader.new("spec/data/rule_130-leader_s.mrc").first
        @record_130_not_s = MARC::Reader.new("spec/data/rule_130-leader_not_s.mrc").first
      end

      it "should convert to 222 if LEADER7 is s" do
        new_record = AdjustLibris::RecordRules.rule_130(@record_130_s)
        expect(new_record['130']).to be_nil
        expect(new_record['222']['a']).to eq("Title with - in its name")
      end

      it "should not convert to 222 if LEADER7 is other than s" do
        new_record = AdjustLibris::RecordRules.rule_130(@record_130_not_s)
        expect(new_record['222']).to be_nil
        expect(new_record['130']['a']).to eq("Title with - in its name")
      end
    end

    context "rule_222" do
      before :each do
        @record_222 = MARC::Reader.new("spec/data/rule_222.mrc").first
      end

      it "should replace _-_ with _/_ if present in $a" do
        new_record = AdjustLibris::RecordRules.rule_222(@record_222)
        expect(new_record['222']['a']).to eq("Title with / in its name")
      end
    end

    context "rule_599" do
      before :each do
        @record_599_s = MARC::Reader.new("spec/data/rule_599-s.mrc").first
        @record_599_not_s = MARC::Reader.new("spec/data/rule_599-not_s.mrc").first
        @record_599_not_blank = MARC::Reader.new("spec/data/rule_599-not_blank.mrc").first
      end

      it "should change ind1 to 1 if ind1 and ind2 are blank and LEADER7 is s" do
        new_record = AdjustLibris::RecordRules.rule_599_ind1(@record_599_s)
        fields = new_record.fields('599')
        expect(fields[0].indicator1).to eq("1")
        expect(fields[0].indicator2).to eq(" ")
      end

      it "should not change ind1 if LEADER7 is other than s" do
        new_record = AdjustLibris::RecordRules.rule_599_ind1(@record_599_not_s)
        fields = new_record.fields('599')
        expect(fields[0].indicator1).to eq(" ")
        expect(fields[0].indicator2).to eq(" ")
      end

      it "should remove 599 where ind1 and ind2 are both blank" do
        new_record = AdjustLibris::RecordRules.rule_599_remove(@record_599_not_s)
        fields = new_record.fields('599')
        expect(fields.count).to eq(0)
      end

      it "should not remove 599 when ind1 or ind2 are set" do
        new_record = AdjustLibris::RecordRules.rule_599_remove(@record_599_not_blank)
        fields = new_record.fields('599')
        expect(fields.count).to eq(1)
      end
    end

    context "rule_440" do
      before :each do
        @record_440 = MARC::Reader.new("spec/data/rule_440.mrc").first
      end

      it "should replace _-_ with _/_ if present in $a" do
        new_record = AdjustLibris::RecordRules.rule_440(@record_440)
        expect(new_record['440']['a']).to eq("Title with / in its name")
      end
    end

    context "rule_830" do
      before :each do
        @record_830 = MARC::Reader.new("spec/data/rule_830.mrc").first
      end

      it "should replace _-_ with _/_ if present in $a" do
        new_record = AdjustLibris::RecordRules.rule_830(@record_830)
        expect(new_record['830']['a']).to eq("Title with / in its name")
      end
    end

    context "rule_650" do
      before :each do
        @record_with_ind2_0 = MARC::Reader.new("spec/data/rule_650-ind2_7fast_with_ind2_0.mrc").first
        @record_without_ind2_0 = MARC::Reader.new("spec/data/rule_650-ind2_7fast_without_ind2_0.mrc").first
        @record_mesh_and_lc_no_dup = MARC::Reader.new("spec/data/rule_650-ind2_2_and_ind2_0_no_dup.mrc").first
        @record_mesh_without_lc = MARC::Reader.new("spec/data/rule_650-ind2_2_without_ind2_0.mrc").first
        @record_mesh_and_lc_with_dup = MARC::Reader.new("spec/data/rule_650-ind2_2_and_ind2_0_with_dup.mrc").first
      end

      it "should remove 650 fields with ind2 == 7 and $2 == fast when any field with ind2 == 0 exists" do
        new_record = AdjustLibris::RecordRules.rule_650_ind2_7fast(@record_with_ind2_0)
        fields = new_record.fields('650')
        fast_fields = fields.select do |field|
          field.indicator2 == '7' && field['2'] == 'fast'
        end
        expect(fast_fields.count).to eq(0)
      end

      it "should remove not 650 fields with ind2 == 7 and $2 == fast when there are no ind2 == 0 fields" do
        new_record = AdjustLibris::RecordRules.rule_650_ind2_7fast(@record_without_ind2_0)
        fields = new_record.fields('650')
        fast_fields = fields.select do |field|
          field.indicator2 == '7' && field['2'] == 'fast'
        end
        expect(fast_fields.count).to eq(3)
      end

      it "should keep all ind2 == 2 when as is when no ind2 == 0 exists" do
        new_record = AdjustLibris::RecordRules.rule_650_ind2_mesh(@record_mesh_without_lc)
        fields = new_record.fields('650')
        mesh_fields = fields.select do |field|
          field.indicator2 == '2'
        end
        expect(mesh_fields.count).to eq(3)
      end

      it "should keep all ind2 == 2 and ind2 == 0 when they do not overlap" do
        new_record = AdjustLibris::RecordRules.rule_650_ind2_mesh(@record_mesh_and_lc_no_dup)
        fields = new_record.fields('650')
        mesh_fields = fields.select do |field|
          field.indicator2 == '2'
        end
        lc_fields = fields.select do |field|
          field.indicator2 == '0'
        end
        expect(mesh_fields.count).to eq(3)
        expect(lc_fields.count).to eq(3)
      end

      it "should keep ind2 == 2 and ind2 == 0 but only ind2 == 2 when duplicate with ind2 == 0" do
        new_record = AdjustLibris::RecordRules.rule_650_ind2_mesh(@record_mesh_and_lc_with_dup)
        fields = new_record.fields('650')
        mesh_fields = fields.select do |field|
          field.indicator2 == '2'
        end
        lc_fields = fields.select do |field|
          field.indicator2 == '0'
        end
        expect(mesh_fields.count).to eq(3)
        expect(lc_fields.count).to eq(1)
      end
    end

    context "rule_648" do
      private def change_field(record, from_tag, to_tag)
        record.fields(from_tag).each do |field|
          record.append(MARC::DataField.new(to_tag, field.indicator1, field.indicator2, *field.subfields))
          record.remove(field)
        end

        record
      end
      
      before :each do
        @record_with_ind2_0 = MARC::Reader.new("spec/data/rule_650-ind2_7fast_with_ind2_0.mrc").first
        @record_without_ind2_0 = MARC::Reader.new("spec/data/rule_650-ind2_7fast_without_ind2_0.mrc").first
        @record_mesh_and_lc_no_dup = MARC::Reader.new("spec/data/rule_650-ind2_2_and_ind2_0_no_dup.mrc").first
        @record_mesh_without_lc = MARC::Reader.new("spec/data/rule_650-ind2_2_without_ind2_0.mrc").first
        @record_mesh_and_lc_with_dup = MARC::Reader.new("spec/data/rule_650-ind2_2_and_ind2_0_with_dup.mrc").first

        change_field(@record_with_ind2_0, '650', '648')
        change_field(@record_without_ind2_0, '650', '648')
        change_field(@record_mesh_and_lc_no_dup, '650', '648')
        change_field(@record_mesh_without_lc, '650', '648')
        change_field(@record_mesh_and_lc_with_dup, '650', '648')
      end

      it "should remove 648 fields with ind2 == 7 and $2 == fast when any field with ind2 == 0 exists" do
        new_record = AdjustLibris::RecordRules.rule_648_ind2_7fast(@record_with_ind2_0)
        fields = new_record.fields('648')
        fast_fields = fields.select do |field|
          field.indicator2 == '7' && field['2'] == 'fast'
        end
        expect(fast_fields.count).to eq(0)
      end

      it "should remove not 648 fields with ind2 == 7 and $2 == fast when there are no ind2 == 0 fields" do
        new_record = AdjustLibris::RecordRules.rule_648_ind2_7fast(@record_without_ind2_0)
        fields = new_record.fields('648')
        fast_fields = fields.select do |field|
          field.indicator2 == '7' && field['2'] == 'fast'
        end
        expect(fast_fields.count).to eq(3)
      end

      it "should keep all ind2 == 2 when as is when no ind2 == 0 exists" do
        new_record = AdjustLibris::RecordRules.rule_648_ind2_mesh(@record_mesh_without_lc)
        fields = new_record.fields('648')
        mesh_fields = fields.select do |field|
          field.indicator2 == '2'
        end
        expect(mesh_fields.count).to eq(3)
      end

      it "should keep all ind2 == 2 and ind2 == 0 when they do not overlap" do
        new_record = AdjustLibris::RecordRules.rule_648_ind2_mesh(@record_mesh_and_lc_no_dup)
        fields = new_record.fields('648')
        mesh_fields = fields.select do |field|
          field.indicator2 == '2'
        end
        lc_fields = fields.select do |field|
          field.indicator2 == '0'
        end
        expect(mesh_fields.count).to eq(3)
        expect(lc_fields.count).to eq(3)
      end

      it "should keep ind2 == 2 and ind2 == 0 but only ind2 == 2 when duplicate with ind2 == 0" do
        new_record = AdjustLibris::RecordRules.rule_648_ind2_mesh(@record_mesh_and_lc_with_dup)
        fields = new_record.fields('648')
        mesh_fields = fields.select do |field|
          field.indicator2 == '2'
        end
        lc_fields = fields.select do |field|
          field.indicator2 == '0'
        end
        expect(mesh_fields.count).to eq(3)
        expect(lc_fields.count).to eq(1)
      end
    end

    context "rule_651" do
      private def change_field(record, from_tag, to_tag)
        record.fields(from_tag).each do |field|
          record.append(MARC::DataField.new(to_tag, field.indicator1, field.indicator2, *field.subfields))
          record.remove(field)
        end

        record
      end
      
      before :each do
        @record_with_ind2_0 = MARC::Reader.new("spec/data/rule_650-ind2_7fast_with_ind2_0.mrc").first
        @record_without_ind2_0 = MARC::Reader.new("spec/data/rule_650-ind2_7fast_without_ind2_0.mrc").first
        @record_mesh_and_lc_no_dup = MARC::Reader.new("spec/data/rule_650-ind2_2_and_ind2_0_no_dup.mrc").first
        @record_mesh_without_lc = MARC::Reader.new("spec/data/rule_650-ind2_2_without_ind2_0.mrc").first
        @record_mesh_and_lc_with_dup = MARC::Reader.new("spec/data/rule_650-ind2_2_and_ind2_0_with_dup.mrc").first

        change_field(@record_with_ind2_0, '650', '651')
        change_field(@record_without_ind2_0, '650', '651')
        change_field(@record_mesh_and_lc_no_dup, '650', '651')
        change_field(@record_mesh_without_lc, '650', '651')
        change_field(@record_mesh_and_lc_with_dup, '650', '651')
      end

      it "should remove 651 fields with ind2 == 7 and $2 == fast when any field with ind2 == 0 exists" do
        new_record = AdjustLibris::RecordRules.rule_651_ind2_7fast(@record_with_ind2_0)
        fields = new_record.fields('651')
        fast_fields = fields.select do |field|
          field.indicator2 == '7' && field['2'] == 'fast'
        end
        expect(fast_fields.count).to eq(0)
      end

      it "should remove not 651 fields with ind2 == 7 and $2 == fast when there are no ind2 == 0 fields" do
        new_record = AdjustLibris::RecordRules.rule_651_ind2_7fast(@record_without_ind2_0)
        fields = new_record.fields('651')
        fast_fields = fields.select do |field|
          field.indicator2 == '7' && field['2'] == 'fast'
        end
        expect(fast_fields.count).to eq(3)
      end

      it "should keep all ind2 == 2 when as is when no ind2 == 0 exists" do
        new_record = AdjustLibris::RecordRules.rule_651_ind2_mesh(@record_mesh_without_lc)
        fields = new_record.fields('651')
        mesh_fields = fields.select do |field|
          field.indicator2 == '2'
        end
        expect(mesh_fields.count).to eq(3)
      end

      it "should keep all ind2 == 2 and ind2 == 0 when they do not overlap" do
        new_record = AdjustLibris::RecordRules.rule_651_ind2_mesh(@record_mesh_and_lc_no_dup)
        fields = new_record.fields('651')
        mesh_fields = fields.select do |field|
          field.indicator2 == '2'
        end
        lc_fields = fields.select do |field|
          field.indicator2 == '0'
        end
        expect(mesh_fields.count).to eq(3)
        expect(lc_fields.count).to eq(3)
      end

      it "should keep ind2 == 2 and ind2 == 0 but only ind2 == 2 when duplicate with ind2 == 0" do
        new_record = AdjustLibris::RecordRules.rule_651_ind2_mesh(@record_mesh_and_lc_with_dup)
        fields = new_record.fields('651')
        mesh_fields = fields.select do |field|
          field.indicator2 == '2'
        end
        lc_fields = fields.select do |field|
          field.indicator2 == '0'
        end
        expect(mesh_fields.count).to eq(3)
        expect(lc_fields.count).to eq(1)
      end
    end

    context "rule_655" do
      private def change_field(record, from_tag, to_tag)
        record.fields(from_tag).each do |field|
          record.append(MARC::DataField.new(to_tag, field.indicator1, field.indicator2, *field.subfields))
          record.remove(field)
        end

        record
      end
      
      before :each do
        @record_with_ind2_0 = MARC::Reader.new("spec/data/rule_650-ind2_7fast_with_ind2_0.mrc").first
        @record_without_ind2_0 = MARC::Reader.new("spec/data/rule_650-ind2_7fast_without_ind2_0.mrc").first
        @record_mesh_and_lc_no_dup = MARC::Reader.new("spec/data/rule_650-ind2_2_and_ind2_0_no_dup.mrc").first
        @record_mesh_without_lc = MARC::Reader.new("spec/data/rule_650-ind2_2_without_ind2_0.mrc").first
        @record_mesh_and_lc_with_dup = MARC::Reader.new("spec/data/rule_650-ind2_2_and_ind2_0_with_dup.mrc").first

        change_field(@record_with_ind2_0, '650', '655')
        change_field(@record_without_ind2_0, '650', '655')
        change_field(@record_mesh_and_lc_no_dup, '650', '655')
        change_field(@record_mesh_without_lc, '650', '655')
        change_field(@record_mesh_and_lc_with_dup, '650', '655')
      end

      it "should remove 655 fields with ind2 == 7 and $2 == fast when any field with ind2 == 0 exists" do
        new_record = AdjustLibris::RecordRules.rule_655_ind2_7fast(@record_with_ind2_0)
        fields = new_record.fields('655')
        fast_fields = fields.select do |field|
          field.indicator2 == '7' && field['2'] == 'fast'
        end
        expect(fast_fields.count).to eq(0)
      end

      it "should remove not 655 fields with ind2 == 7 and $2 == fast when there are no ind2 == 0 fields" do
        new_record = AdjustLibris::RecordRules.rule_655_ind2_7fast(@record_without_ind2_0)
        fields = new_record.fields('655')
        fast_fields = fields.select do |field|
          field.indicator2 == '7' && field['2'] == 'fast'
        end
        expect(fast_fields.count).to eq(3)
      end

      it "should keep all ind2 == 2 when as is when no ind2 == 0 exists" do
        new_record = AdjustLibris::RecordRules.rule_655_ind2_mesh(@record_mesh_without_lc)
        fields = new_record.fields('655')
        mesh_fields = fields.select do |field|
          field.indicator2 == '2'
        end
        expect(mesh_fields.count).to eq(3)
      end

      it "should keep all ind2 == 2 and ind2 == 0 when they do not overlap" do
        new_record = AdjustLibris::RecordRules.rule_655_ind2_mesh(@record_mesh_and_lc_no_dup)
        fields = new_record.fields('655')
        mesh_fields = fields.select do |field|
          field.indicator2 == '2'
        end
        lc_fields = fields.select do |field|
          field.indicator2 == '0'
        end
        expect(mesh_fields.count).to eq(3)
        expect(lc_fields.count).to eq(3)
      end

      it "should keep ind2 == 2 and ind2 == 0 but only ind2 == 2 when duplicate with ind2 == 0" do
        new_record = AdjustLibris::RecordRules.rule_655_ind2_mesh(@record_mesh_and_lc_with_dup)
        fields = new_record.fields('655')
        mesh_fields = fields.select do |field|
          field.indicator2 == '2'
        end
        lc_fields = fields.select do |field|
          field.indicator2 == '0'
        end
        expect(mesh_fields.count).to eq(3)
        expect(lc_fields.count).to eq(1)
      end
    end

    context "rule_760" do
      before :each do
        @record = MARC::Reader.new("spec/data/rule_760.mrc").first
      end

      it "should remove hyphens in 760$w 760$x and 760$z" do
        new_record = AdjustLibris::RecordRules.rule_760(@record)
        fields = new_record.fields('760')
        expect(fields[1]['w']).to eq('13229222333')
        expect(fields[2]['x']).to eq('13229222333')
        expect(fields[2]['z']).to eq('1129233333')
      end

      it "should not remove hyphens in 760$w 760$x and 760$z if it matches an ISSN (####-####)" do
        new_record = AdjustLibris::RecordRules.rule_760(@record)
        fields = new_record.fields('760')
        expect(fields[0]['w']).to eq('1234-567X')
        expect(fields[1]['x']).to eq('1111-1234')
      end
    end

    context "rule_762" do
      private def change_field(record, from_tag, to_tag)
        record.fields(from_tag).each do |field|
          record.append(MARC::DataField.new(to_tag, field.indicator1, field.indicator2, *field.subfields))
          record.remove(field)
        end

        record
      end
      
      before :each do
        @record = MARC::Reader.new("spec/data/rule_760.mrc").first
        @record = change_field(@record, '760', '762')
      end

      it "should remove hyphens in 762$w 762$x and 762$z" do
        new_record = AdjustLibris::RecordRules.rule_762(@record)
        fields = new_record.fields('762')
        expect(fields[1]['w']).to eq('13229222333')
        expect(fields[2]['x']).to eq('13229222333')
        expect(fields[2]['z']).to eq('1129233333')
      end

      it "should not remove hyphens in 762$w 762$x and 762$z if it matches an ISSN (####-####)" do
        new_record = AdjustLibris::RecordRules.rule_762(@record)
        fields = new_record.fields('762')
        expect(fields[0]['w']).to eq('1234-567X')
        expect(fields[1]['x']).to eq('1111-1234')
      end
    end

    context "rule_765" do
      private def change_field(record, from_tag, to_tag)
        record.fields(from_tag).each do |field|
          record.append(MARC::DataField.new(to_tag, field.indicator1, field.indicator2, *field.subfields))
          record.remove(field)
        end

        record
      end
      
      before :each do
        @record = MARC::Reader.new("spec/data/rule_760.mrc").first
        @record = change_field(@record, '760', '765')
      end

      it "should remove hyphens in 765$w 765$x and 765$z" do
        new_record = AdjustLibris::RecordRules.rule_765(@record)
        fields = new_record.fields('765')
        expect(fields[1]['w']).to eq('13229222333')
        expect(fields[2]['x']).to eq('13229222333')
        expect(fields[2]['z']).to eq('1129233333')
      end

      it "should not remove hyphens in 765$w 765$x and 765$z if it matches an ISSN (####-####)" do
        new_record = AdjustLibris::RecordRules.rule_765(@record)
        fields = new_record.fields('765')
        expect(fields[0]['w']).to eq('1234-567X')
        expect(fields[1]['x']).to eq('1111-1234')
      end
    end

    context "rule_767" do
      private def change_field(record, from_tag, to_tag)
        record.fields(from_tag).each do |field|
          record.append(MARC::DataField.new(to_tag, field.indicator1, field.indicator2, *field.subfields))
          record.remove(field)
        end

        record
      end
      
      before :each do
        @record = MARC::Reader.new("spec/data/rule_760.mrc").first
        @record = change_field(@record, '760', '767')
      end

      it "should remove hyphens in 767$w 767$x and 767$z" do
        new_record = AdjustLibris::RecordRules.rule_767(@record)
        fields = new_record.fields('767')
        expect(fields[1]['w']).to eq('13229222333')
        expect(fields[2]['x']).to eq('13229222333')
        expect(fields[2]['z']).to eq('1129233333')
      end

      it "should not remove hyphens in 767$w 767$x and 767$z if it matches an ISSN (####-####)" do
        new_record = AdjustLibris::RecordRules.rule_767(@record)
        fields = new_record.fields('767')
        expect(fields[0]['w']).to eq('1234-567X')
        expect(fields[1]['x']).to eq('1111-1234')
      end
    end

    context "rule_770" do
      private def change_field(record, from_tag, to_tag)
        record.fields(from_tag).each do |field|
          record.append(MARC::DataField.new(to_tag, field.indicator1, field.indicator2, *field.subfields))
          record.remove(field)
        end

        record
      end
      
      before :each do
        @record = MARC::Reader.new("spec/data/rule_760.mrc").first
        @record = change_field(@record, '760', '770')
      end

      it "should remove hyphens in 770$w 770$x and 770$z" do
        new_record = AdjustLibris::RecordRules.rule_770(@record)
        fields = new_record.fields('770')
        expect(fields[1]['w']).to eq('13229222333')
        expect(fields[2]['x']).to eq('13229222333')
        expect(fields[2]['z']).to eq('1129233333')
      end

      it "should not remove hyphens in 770$w 770$x and 770$z if it matches an ISSN (####-####)" do
        new_record = AdjustLibris::RecordRules.rule_770(@record)
        fields = new_record.fields('770')
        expect(fields[0]['w']).to eq('1234-567X')
        expect(fields[1]['x']).to eq('1111-1234')
      end
    end

    context "rule_772" do
      private def change_field(record, from_tag, to_tag)
        record.fields(from_tag).each do |field|
          record.append(MARC::DataField.new(to_tag, field.indicator1, field.indicator2, *field.subfields))
          record.remove(field)
        end

        record
      end
      
      before :each do
        @record = MARC::Reader.new("spec/data/rule_760.mrc").first
        @record = change_field(@record, '760', '772')
      end

      it "should remove hyphens in 772$w 772$x and 772$z" do
        new_record = AdjustLibris::RecordRules.rule_772(@record)
        fields = new_record.fields('772')
        expect(fields[1]['w']).to eq('13229222333')
        expect(fields[2]['x']).to eq('13229222333')
        expect(fields[2]['z']).to eq('1129233333')
      end

      it "should not remove hyphens in 772$w 772$x and 772$z if it matches an ISSN (####-####)" do
        new_record = AdjustLibris::RecordRules.rule_772(@record)
        fields = new_record.fields('772')
        expect(fields[0]['w']).to eq('1234-567X')
        expect(fields[1]['x']).to eq('1111-1234')
      end
    end

    context "rule_776" do
      private def change_field(record, from_tag, to_tag)
        record.fields(from_tag).each do |field|
          record.append(MARC::DataField.new(to_tag, field.indicator1, field.indicator2, *field.subfields))
          record.remove(field)
        end

        record
      end
      
      before :each do
        @record = MARC::Reader.new("spec/data/rule_760.mrc").first
        @record = change_field(@record, '760', '776')
      end

      it "should remove hyphens in 776$w 776$x and 776$z" do
        new_record = AdjustLibris::RecordRules.rule_776(@record)
        fields = new_record.fields('776')
        expect(fields[1]['w']).to eq('13229222333')
        expect(fields[2]['x']).to eq('13229222333')
        expect(fields[2]['z']).to eq('1129233333')
      end

      it "should not remove hyphens in 776$w 776$x and 776$z if it matches an ISSN (####-####)" do
        new_record = AdjustLibris::RecordRules.rule_776(@record)
        fields = new_record.fields('776')
        expect(fields[0]['w']).to eq('1234-567X')
        expect(fields[1]['x']).to eq('1111-1234')
      end
    end

    context "rule_779" do
      private def change_field(record, from_tag, to_tag)
        record.fields(from_tag).each do |field|
          record.append(MARC::DataField.new(to_tag, field.indicator1, field.indicator2, *field.subfields))
          record.remove(field)
        end

        record
      end
      
      before :each do
        @record = MARC::Reader.new("spec/data/rule_760.mrc").first
        @record = change_field(@record, '760', '779')
      end

      it "should remove hyphens in 779$w 779$x and 779$z" do
        new_record = AdjustLibris::RecordRules.rule_779(@record)
        fields = new_record.fields('779')
        expect(fields[1]['w']).to eq('13229222333')
        expect(fields[2]['x']).to eq('13229222333')
        expect(fields[2]['z']).to eq('1129233333')
      end

      it "should not remove hyphens in 779$w 779$x and 779$z if it matches an ISSN (####-####)" do
        new_record = AdjustLibris::RecordRules.rule_779(@record)
        fields = new_record.fields('779')
        expect(fields[0]['w']).to eq('1234-567X')
        expect(fields[1]['x']).to eq('1111-1234')
      end
    end

    context "rule_780" do
      private def change_field(record, from_tag, to_tag)
        record.fields(from_tag).each do |field|
          record.append(MARC::DataField.new(to_tag, field.indicator1, field.indicator2, *field.subfields))
          record.remove(field)
        end

        record
      end
      
      before :each do
        @record = MARC::Reader.new("spec/data/rule_760.mrc").first
        @record = change_field(@record, '760', '780')
      end

      it "should remove hyphens in 780$w 780$x and 780$z" do
        new_record = AdjustLibris::RecordRules.rule_780(@record)
        fields = new_record.fields('780')
        expect(fields[1]['w']).to eq('13229222333')
        expect(fields[2]['x']).to eq('13229222333')
        expect(fields[2]['z']).to eq('1129233333')
      end

      it "should not remove hyphens in 780$w 780$x and 780$z if it matches an ISSN (####-####)" do
        new_record = AdjustLibris::RecordRules.rule_780(@record)
        fields = new_record.fields('780')
        expect(fields[0]['w']).to eq('1234-567X')
        expect(fields[1]['x']).to eq('1111-1234')
      end
    end

    context "rule_785" do
      private def change_field(record, from_tag, to_tag)
        record.fields(from_tag).each do |field|
          record.append(MARC::DataField.new(to_tag, field.indicator1, field.indicator2, *field.subfields))
          record.remove(field)
        end

        record
      end
      
      before :each do
        @record = MARC::Reader.new("spec/data/rule_760.mrc").first
        @record = change_field(@record, '760', '785')
      end

      it "should remove hyphens in 785$w 785$x and 785$z" do
        new_record = AdjustLibris::RecordRules.rule_785(@record)
        fields = new_record.fields('785')
        expect(fields[1]['w']).to eq('13229222333')
        expect(fields[2]['x']).to eq('13229222333')
        expect(fields[2]['z']).to eq('1129233333')
      end

      it "should not remove hyphens in 785$w 785$x and 785$z if it matches an ISSN (####-####)" do
        new_record = AdjustLibris::RecordRules.rule_785(@record)
        fields = new_record.fields('785')
        expect(fields[0]['w']).to eq('1234-567X')
        expect(fields[1]['x']).to eq('1111-1234')
      end
    end

    context "rule_787" do
      private def change_field(record, from_tag, to_tag)
        record.fields(from_tag).each do |field|
          record.append(MARC::DataField.new(to_tag, field.indicator1, field.indicator2, *field.subfields))
          record.remove(field)
        end

        record
      end
      
      before :each do
        @record = MARC::Reader.new("spec/data/rule_760.mrc").first
        @record = change_field(@record, '760', '787')
      end

      it "should remove hyphens in 787$w 787$x and 787$z" do
        new_record = AdjustLibris::RecordRules.rule_787(@record)
        fields = new_record.fields('787')
        expect(fields[1]['w']).to eq('13229222333')
        expect(fields[2]['x']).to eq('13229222333')
        expect(fields[2]['z']).to eq('1129233333')
      end

      it "should not remove hyphens in 787$w 787$x and 787$z if it matches an ISSN (####-####)" do
        new_record = AdjustLibris::RecordRules.rule_787(@record)
        fields = new_record.fields('787')
        expect(fields[0]['w']).to eq('1234-567X')
        expect(fields[1]['x']).to eq('1111-1234')
      end
    end

    context "rule_440" do
      private def change_field(record, from_tag, to_tag)
        record.fields(from_tag).each do |field|
          record.append(MARC::DataField.new(to_tag, field.indicator1, field.indicator2, *field.subfields))
          record.remove(field)
        end

        record
      end
      
      before :each do
        @record = MARC::Reader.new("spec/data/rule_760.mrc").first
        @record = change_field(@record, '760', '440')
      end

      it "should remove hyphens in 440$w 440$x and 440$z" do
        new_record = AdjustLibris::RecordRules.rule_440(@record)
        fields = new_record.fields('440')
        expect(fields[1]['w']).to eq('13229222333')
        expect(fields[2]['x']).to eq('13229222333')
        expect(fields[2]['z']).to eq('1129233333')
      end

      it "should not remove hyphens in 440$w 440$x and 440$z if it matches an ISSN (####-####)" do
        new_record = AdjustLibris::RecordRules.rule_440(@record)
        fields = new_record.fields('440')
        expect(fields[0]['w']).to eq('1234-567X')
        expect(fields[1]['x']).to eq('1111-1234')
      end
    end

    context "rule_852" do
      before :each do
        @record_old_with_c = MARC::Reader.new("spec/data/rule_852_old_with_c.mrc").first
        @record_old_serial_with_c = MARC::Reader.new("spec/data/rule_852_old_serial_with_c.mrc").first
        @record_old_without_c = MARC::Reader.new("spec/data/rule_852_old_without_c.mrc").first
        @record_new_with_c = MARC::Reader.new("spec/data/rule_852_new_with_c.mrc").first
      end

      it "should clean 852 without \\c when any 852 contains \\c" do
        new_record = AdjustLibris::RecordRules.rule_852(@record_old_with_c)
        fields = new_record.fields('852')
        expect(fields.count).to eq(3)
      end

      it "should not clean 852 when no 852 contains \\c" do
        new_record = AdjustLibris::RecordRules.rule_852(@record_old_without_c)
        fields = new_record.fields('852')
        expect(fields.count).to eq(4)
      end

      it "should not clean 852 if record is newer than 2001" do
        new_record = AdjustLibris::RecordRules.rule_852(@record_new_with_c)
        fields = new_record.fields('852')
        expect(fields.count).to eq(4)
      end

      it "should not clean 852 if record other than monograph" do
        new_record = AdjustLibris::RecordRules.rule_852(@record_old_serial_with_c)
        fields = new_record.fields('852')
        expect(fields.count).to eq(4)
      end
    end

    context "rule_852_required" do
      before :each do
        @record_without_852 = MARC::Reader.new("spec/data/rule_852_required.mrc").first
      end

      it "should raise exception on record with 003 as LIBRIS and 852 is missing" do
        expect {
          AdjustLibris::RecordRules.rule_852_required(@record_without_852)
        }.to raise_error(NonLibraryAffiliatedRecord)
      end
    end
    
    context "rule_866" do
      private def change_field(record, from_tag, to_tag)
        record.fields(from_tag).each do |field|
          record.append(MARC::DataField.new(to_tag, field.indicator1, field.indicator2, *field.subfields))
          record.remove(field)
        end

        record
      end
      
      before :each do
        @record_old_with_c = MARC::Reader.new("spec/data/rule_852_old_with_c.mrc").first
        @record_old_serial_with_c = MARC::Reader.new("spec/data/rule_852_old_serial_with_c.mrc").first
        @record_old_without_c = MARC::Reader.new("spec/data/rule_852_old_without_c.mrc").first
        @record_new_with_c = MARC::Reader.new("spec/data/rule_852_new_with_c.mrc").first

        @record_old_with_c = change_field(@record_old_with_c, '852', '866')
        @record_old_serial_with_c = change_field(@record_old_serial_with_c, '852', '866')
        @record_old_without_c = change_field(@record_old_without_c, '852', '866')
        @record_new_with_c = change_field(@record_new_with_c, '852', '866')
      end

      it "should clean 866 without \\c when any 866 contains \\c" do
        new_record = AdjustLibris::RecordRules.rule_866(@record_old_with_c)
        fields = new_record.fields('866')
        expect(fields.count).to eq(3)
      end

      it "should not clean 866 when no 866 contains \\c" do
        new_record = AdjustLibris::RecordRules.rule_866(@record_old_without_c)
        fields = new_record.fields('866')
        expect(fields.count).to eq(4)
      end

      it "should not clean 866 if record is newer than 2001" do
        new_record = AdjustLibris::RecordRules.rule_866(@record_new_with_c)
        fields = new_record.fields('866')
        expect(fields.count).to eq(4)
      end

      it "should not clean 866 if record other than monograph" do
        new_record = AdjustLibris::RecordRules.rule_866(@record_old_serial_with_c)
        fields = new_record.fields('866')
        expect(fields.count).to eq(4)
      end
    end

    context "rule_976" do
      before :each do
        @record = MARC::Reader.new("spec/data/rule_976.mrc").first
#        @record_830 = MARC::Reader.new("spec/data/rule_830.mrc").first
#        w = MARC::Writer.new("spec/data/rule_976.mrc")
#        rec = AdjustLibris::RecordRules.clone(@record_830)
#        rec.remove('976')
#        rec.append(MARC::DataField.new('976', ' ', ' ', ['a', 'Abc'], ['b', 'Test Test Test']))
#        w.write(rec)
#        w.close
      end

      it "should remove 976$a and move $b to $a" do
        new_record = AdjustLibris::RecordRules.rule_976(@record)
        expect(new_record['976']['a']).to eq("Test Test Test")
        expect(new_record['976']['b']).to be_nil
      end
    end
  end
end
