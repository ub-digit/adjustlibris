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
  end
end
