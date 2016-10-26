describe "AdjustLibris Base" do
  before :each do
    @valid_marc21_file = "spec/data/valid-marc21.mrc"
    @invalid_marc21_file = "spec/data/invalid-marc21.mrc"
    @dummy_output_file = "spec/temp/dummy_output.mrc"
    @test_output_file = "spec/temp/test_output.mrc"
  end
  
  context "Input parameters" do
    it "should give error if input file contains invalid MARC21" do
      expect{AdjustLibris.run(input_file: @invalid_marc21_file, output_file: @dummy_output_file)}
        .to raise_error(MARC::Exception)
    end

    it "should not give error if input file contains valid MARC21" do
      expect{AdjustLibris.run(input_file: @valid_marc21_file, output_file: @dummy_output_file)}
        .to_not raise_error
    end
  end

  context "Output parameters" do
    it "should produce valid MARC21 out" do
      AdjustLibris.run(input_file: @valid_marc21_file, output_file: @test_output_file)

      # Loop through all records to trigger any error that may exist
      expect{MARC::Reader.new(@test_output_file).each { |_record| _record }}
        .to_not raise_error
    end
  end
end
