require_relative 'file_streamer.rb'
require_relative 'util.rb'
require_relative 'defines.rb'

class S88Converter
	Int600 = 1.0 / 600


	def initialize
		@dumpFile = String.new
	end

	def buildRawDumpData
		@s98File.reset(@s98DumpOffset)
		outFile = Array.new
		currentPort = 0
		@totalTime = 0.0
		@totalDelays = 0.0
		@loopOffset = 0
		@remainderTime = 0.0
		@dumpFile.concat("S88 Dump\n")
		while !@s98File.eof
			off = @s98File.offset
			if off == @s98LoopOffset
				@loopOffset = outFile.length
				@dumpFile.concat("Loop point at position %d\n" % @loopOffset)
			elsif (outFile.length % 0x1000) + 1 == 0
				outFile.push 0xFF
			end
			cmd = @s98File.readByte
			case cmd
			when 0xFD # end of file
				@dumpFile.concat("%3.3f: EOF/Loop\n" % @totalTime)
				outFile.push 0xFC
				#outFile.push 0xFF
				return outFile
			when 0xFE # wait Nsync
				waitCount = 0
				byteCount = 0
				data = cmd
				while data >= 0x80
					data = @s98File.readByte
					waitCount += (data & 0x7F) << (7*byteCount)
					byteCount += 1
				end
				waitCount += 2
				time, delayAmount = calcDelay(waitCount)
				@totalDelays += delayAmount
				@totalTime += time
				@dumpFile.concat("%3.3f: Delay %d ticks (total %d ticks), %2.3f sec.\n" % [@totalTime, delayAmount, @totalDelays, time])
				if delayAmount >= 0x10000
					raise "Delay too big"
				elsif delayAmount >= 0x100
					@dumpFile.concat("Delay > 255\n")
					outFile.push 0xFE
					outFile.push (delayAmount/0x100).to_i
					outFile.push 0xFD
					outFile.push (delayAmount%0x100).to_i
				elsif delayAmount > 0 && delayAmount < 0x100
					outFile.push 0xFD
					outFile.push delayAmount
				end
			when 0xFF # wait 1 sync
				time, delayAmount = calcDelay(1)
				@totalTime += time
				@totalDelays += delayAmount
				@dumpFile.concat("%3.3f: Delay %d ticks (total %d ticks), %2.3f sec.\n" % [@totalTime, delayAmount, @totalDelays, time])
				if delayAmount > 0
					outFile.push 0xFD
					outFile.push delayAmount
				end
			when 0,1
				if cmd != currentPort
					# switch port
					outFile.push(0xF0 + cmd)
					currentPort = cmd
				end
				reg = @s98File.readByte
				data = @s98File.readByte
				# adjust SSG
				if @modSSG && currentPort == 0 && reg >= 0x08 && reg <= 0x0A
                    ssgVal = data & 0x0F
                    if ssgVal >= 14
                        ssgVal -= 2
                    elsif ssgVal >= 10
                        ssgVal -= 1
                    end
					data = ssgVal + (data&0x10)
				end

				@dumpFile.concat("%3.3f: Port %d reg %02x data %02x\n" % [@totalTime, currentPort, reg, data])
				outFile.push reg
				outFile.push data
			else
				raise "Unknown command: %s"  % [cmd.to_s]
			end
		end
		outFile.push 0xFC
		return outFile
	end

	ChunkSize = 16384
	LoopChunkSize = 4096
	BufferSize = 1024*7

	def compressChunk(_rawDump, _offset, _isLoop = false )
		offset = _offset
		loopCount = 1
		if not _isLoop
			# Determine optimal chunk size
			chunkSize = ChunkSize
			loop do
				chunk = _rawDump[offset, chunkSize].pack('C*')
				cmdLine = '"' + Paths::LZSA_Exe + '" -f 2 -r --prefer-ratio - -'
				compChunk, s = Open3.capture2(cmdLine, :stdin_data => chunk, :binmode => true)
				if compChunk.length >= BufferSize
					if chunkSize == 0x1000 # can't divide anymore
						raise "Can't construct block"
					else
						chunkSize /= 2
						loopCount *= 2
					end
				else
					break
				end
			end
		else
			chunkSize = LoopChunkSize
		end
		chunks = []
		loopCount.times do |i|
			chunk = _rawDump[offset + i*chunkSize, chunkSize].pack('C*')
			chunks.push chunk
		end
		chunks.each_with_index do |c, i|
			cmdLine = '"' + Paths::LZSA_Exe + '" -f 2 -r --prefer-ratio - -'
			compChunk, s = Open3.capture2(cmdLine, :stdin_data => c, :binmode => true)
			if compChunk.length >= BufferSize
				raise "Can't encode"
			end
			@compStream += Util.n2b(compChunk.length, 2)
			# compose flags
			flags = 1
			if chunkSize == 0x4000
				flags += 0
			elsif chunkSize == 0x2000
				flags += 0x04
			elsif chunkSize == 0x1000
				flags += 0x08
			else
				raise "Unsupported chunk size"
			end
			@compStream.push(flags) # flags
			@compStream.push(0x00) # reserved

			@compStream += compChunk.unpack("C*")
			p "Chunk %d 0x%4x: %d" %[ @chunkCount,chunkSize, compChunk.length]
			if compChunk.length >= 1024*7
				raise "error"
			end
			#IO.binwrite(ARGV[1] + "."+@chunkCount.to_s, compChunk)
			prevOffset = offset

			@chunkCount += 1

			offset += chunkSize
			if @loopOffset > 0 && @loopOffset >= prevOffset && @loopOffset <= offset
				@loopBlockOffset = @loopOffset - prevOffset
				@loopBlockNum = @chunkCount - 1
			end
		end
		return offset
	end

#"..\Temp\TH5_00.s98" "..\Temp\TH5_00.s88"


	def buildCompressedStream(_rawDump)
		@compStream = Array.new
		curOffset = 0
		@chunkCount = 0
		if @loopOffset > 0
			compressChunk(_rawDump, @loopOffset, true)
		end
		while curOffset < _rawDump.length

			curOffset = compressChunk(_rawDump, curOffset)

		end

	end

	def calcDelay(_waitCount)
		time = _waitCount * @s98TimerInterval
		delayAmount = ((@remainderTime + time) / Int600)
		@remainderTime = (delayAmount - delayAmount.round()) * Int600
		return time, delayAmount.round()
	end

	def convert(_s98File, _modSSG = true)
		@s98File = FileStreamer.new(_s98File)
		@loopBlockNum = 0
		@loopBlockOffset = 0
		@modSSG = _modSSG

		@s98File.reset(0x4)
		timer1 = @s98File.readLong
		if timer1 == 0
			timer1 = 10
		end
		timer2 = @s98File.readLong
		if timer2 == 0
			timer2 = 1000
		end

		@s98TimerInterval = timer1 * 1.0 / timer2

		@s98File.reset(0x14)
		@s98DumpOffset = @s98File.readLong
		@s98LoopOffset = @s98File.readLong

		header = Array.new
		rawDump = buildRawDumpData()
		#IO.binwrite(ARGV[1] + ".raw", rawDump.pack('C*'))
		#IO.binwrite(ARGV[1] + ".dmp", @dumpFile)

		buildCompressedStream(rawDump)

		# Build header
		header += [0x53, 0x38, 0x38, 0x31]
		header.push 0 # flags
		header.push 0 # timing source
		header.push 1 # timing clock
		header.push 0
		header += Util.n2b(@chunkCount,2)
		header.push 0 # sample count
		header.push 0
		header.push 0
		header.push 0
		header += Util.n2b(@loopBlockOffset,2)
		header += Util.n2b(@loopBlockNum,2)
		14.times {header.push 0}    # reserved
		0x3E0.times {header.push 0} # tag data
		header.reverse_each { |x| @compStream.unshift(x) }

		return @compStream.clone

	end
end

def main
	if ARGV.length != 2
		raise "usage s98conv s98file outfile"
	end

	s88Conv = S88Converter.new
	outFile = s88Conv.convert(ARGV[0])
	IO.binwrite(ARGV[1], outFile.pack('C*'))

end
