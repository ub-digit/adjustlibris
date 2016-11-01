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
  end
end
