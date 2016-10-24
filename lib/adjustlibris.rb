class AdjustLibris
  def self.run(input_file:, output_file:)
    # Do nothing yet, just write file as it is back to disk.
    File.open(input_file, "rb") do |in_f| 
      File.open(output_file, "wb") do |out_f|
        out_f.write(in_f.read)
      end
    end
  end
end
