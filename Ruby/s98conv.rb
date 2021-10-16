require_relative 'file_streamer.rb'

def main
	if ARGV.length != 2
		raise "usage s98conv s98file outfile"
	end
	s98File = FileStreamer.new(ARGV[0])
	s98File.reset(0x14)
	dumpOffset = s98File.readLong
	s98File.reset(dumpOffset)
	outFile = Array.new
	port = 0
	loop do 
		cmd = s98File.readByte
		case cmd
			when 0xFD # end of file
				outFile.push 0xFD
				break
			when 0xFE # wait
				outFile.push 0xFE
				while cmd >= 0x80
					cmd = s98File.readByte
					outFile.push cmd
				end
			when 0xFF
				outFile.push 0xFE
				outFile.push 0x01
			when 0,1
				if cmd != port
					# switch port
					outFile.push(0xF0 + cmd)
					port = cmd
				end
				outFile.push s98File.readByte # reg
				outFile.push s98File.readByte # data
			else
				raise "Unknown command"
		end
	end
	IO.binwrite(ARGV[1], outFile.pack('C*'))
end

main