describe "AdjustLibris::RecordRules" do
  
  context "Rules" do
    context "rule_041" do
      before :each do
        marc21_file = "spec/data/without-041.mrc"
        @record = MARC::Reader.new(marc21_file).first
      end
      
      it "should apply rule" do
        new_record = AdjustLibris::RecordRules.rule_041(@record)
        expect(new_record["041"]).to be_kind_of(MARC::DataField)
        expect(new_record["041"]["a"]).to eq("eng")
      end
    end
  end
end
