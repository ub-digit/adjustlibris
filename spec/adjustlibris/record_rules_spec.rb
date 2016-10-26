describe "AdjustLibris::RecordRules" do
  before :each do
    marc21_file = "spec/data/valid-marc21.mrc"
    @record1 = MARC::Reader.new(marc21_file).first
  end
  
  context "Rules" do
    # Dummy test since there are no rules
    it "should apply rule 1" do
      
    end
  end
end
