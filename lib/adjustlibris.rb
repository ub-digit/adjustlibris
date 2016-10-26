require 'marc'
require_relative 'adjustlibris/record_rules'

class AdjustLibris
  def self.run(input_file:, output_file:)
    reader = MARC::Reader.new(input_file)
    writer = MARC::Writer.new(output_file)
    reader.each do |record|
      writer.write(AdjustLibris::RecordRules.apply(record))
    end
  end
end
