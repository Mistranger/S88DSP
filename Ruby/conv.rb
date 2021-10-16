require_relative 'defines.rb'
require_relative 's88conv.rb'

directory = File.expand_path(Paths::S98Import.chomp)
files = Dir.glob("#{directory}/*.s98")
ssgFix = false
if ARGV.length > 0
    p "SSG volume fix applied"
    ssgFix = true
else 
    p "SSG volume fix not applied"
end
files.each do |f|
  p "Converting %s" % f
  s88Conv = S88Converter.new
  outFile = s88Conv.convert(f, ssgFix )
  IO.binwrite(Paths::Music + File.basename(f,".s98") + '.s88', outFile.pack('C*'))
end