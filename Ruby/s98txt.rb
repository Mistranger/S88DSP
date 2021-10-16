require_relative "file_streamer.rb"

class S98Parser
    def initialize(inFile, outFile = nil)
        @s98File = FileStreamer.new(inFile)
        @textOut = String.new(:capacity => @s98File.length)
        if outFile == nil
            @outFile = "dumpFile.txt"
        end
        @deviceInfoData = {
            0 => {:mName => "None", :mPorts => 0},
            1 => {:mName => "PSG (YM2149)", :mPorts => 1},
            2 => {:mName => "OPN (YM2203)", :mPorts => 1},
            3 => {:mName => "OPN2 (YM2612)", :mPorts => 2},
            4 => {:mName => "OPNA (YM2608)", :mPorts => 2},
            5 => {:mName => "OPM (YM2151)", :mPorts => 1},
            6 => {:mName => "OPLL (YM2413)", :mPorts => 1},
            7 => {:mName => "OPL (YM3526)", :mPorts => 1},
            8 => {:mName => "OPL2 (YM3812)", :mPorts => 1},
            9 => {:mName => "OPL3 (YMF262)", :mPorts => 2},
            15 => {:mName => "PSG (AY-3-8910)", :mPorts => 1},
            16 => {:mName => "DCSG (SN76489)", :mPorts => 1}
        }
    end

    def errorMsg(_msg)
        p _msg
        exit
    end

    def parseDevices()
        @textOut.concat "---- Devices ----\n"
        @sDeviceData = []
        if @sDeviceCount > 0
            @sDeviceCount.times do |i|
                sDeviceType = @s98File.readLong
                sClock = @s98File.readLong
                sPan = @s98File.readLong
                sReserve = @s98File.readLong

                devType = @deviceInfoData[sDeviceType]
                if devType.nil?
                    errorMsg "Unknown device: %d" % sDeviceType
                end
                @textOut.concat "Device: type %d - %s \n" % [sDeviceType, devType[:mName]]
                @textOut.concat "Clock: %d \n" % [sClock]
                @textOut.concat "Pan: %d \n" % [sPan]

                @sDeviceData.push({:sDeviceType => sDeviceType, :sClock => sClock, :sPan => sPan})
            end
            @textOut.concat "\n"
        else
            @textOut.concat "No devices specified, OPNA is assumed\n"
            @sDeviceData.push({:sDeviceType => 4, :sClock => 7987200, :sPan => 0})
        end
    end

    def parseTagData()

        curOffset = @s98File.offset
        @s98File.reset(@sTagOffset)
        sTagHeader = @s98File.readBytes(5).pack('c*')
        if sTagHeader != '[S98]'
            errorMsg "Invalid TAG format"
        end
        @textOut.concat "---- TAG data ----\n"
        sUTF8 = @s98File.readBytes(3, @s98File.offset)
        sUTF8Mode = sUTF8.eql?([0xEF, 0xBB, 0xBF])
        while !@s98File.eof
            tag = @s98File.readString(0x0a).pack('c*')
            if !sUTF8Mode
                tag.encode!("utf-8", "shift_jis")
            end
            @textOut.concat tag
        end
        @textOut.concat "---- End of TAG data ----\n"
        @textOut.concat "\n"
        @s98File.reset(curOffset)
    end

    def parseHeaderTagData()
        @sTimer1 = @s98File.readLong
        @sTimer2 = @s98File.readLong
        @sComp = @s98File.readLong
        @sTagOffset = @s98File.readLong
        @sDumpOffset = @s98File.readLong
        @sLoopOffset = @s98File.readLong
        @sDeviceCount = @s98File.readLong

        @textOut.concat "---- Header ----\n"
        @textOut.concat "Timer Info 1: %d (0x%08x)" % [@sTimer1, @sTimer1]
        if @sTimer1 == 0
            @textOut.concat "(defaulting to 10)\n"
            @sTimer1 = 10
        else
            @textOut.concat "\n"
        end
        @textOut.concat "Timer Info 2: %d (0x%08x)" % [@sTimer2, @sTimer2]
        if @sTimer2 == 0
            @textOut.concat " (defaulting to 1000)\n"
            @sTimer2 = 1000
        else
            @textOut.concat "\n"
        end
        @textOut.concat "Compressing: %d\n" % [@sComp]
        @textOut.concat "Offset to TAG section: 0x%08x\n" % [@sTagOffset]
        @textOut.concat "Offset to dump data: 0x%08x\n" % [@sDumpOffset]
        @textOut.concat "Offset to loop section: 0x%08x\n" % [@sLoopOffset]
        @textOut.concat "Device count: %d\n" % [@sDeviceCount]
        @textOut.concat "\n"

        parseDevices

        if @sTagOffset != 0
            parseTagData
        end
    end

    def decode_YM2608(_port, _reg, _data)
        str = ""
    end

    def parseDumpData
        totalTime = 0.0
        @s98File.reset(@sDumpOffset)
        @textOut.concat "---- Dump data ----\n"
        if @sTagOffset != 0
            endOffset = @sTagOffset
        else
            endOffset = @s98File.length
        end

        while @s98File.offset < endOffset
            #p @s98File.offset
            off = @s98File.offset
            if off == @sLoopOffset
                @textOut.concat "**** Loop point ****\n"
            end
            @textOut.concat "%4.3f  0x%08x  " % [totalTime, off]

            cmd = @s98File.readByte
            if cmd == 0xFF # 1SYNC
                time = @sTimer1 * 1.0 / @sTimer2
                @textOut.concat "%02x          " % cmd
                @textOut.concat "Wait 1 SYNC (%.3f s.)" % [time]
                totalTime += time
            elsif cmd == 0xFE #nSYNC
                @textOut.concat "%02x " % cmd
                data = cmd
                waitCount = 0
                byteCount = 0
                while data >= 0x80
                    data = @s98File.readByte
                    @textOut.concat "%02x " % data
                    waitCount += (data & 0x7F) << (7*byteCount)
                    byteCount += 1
                end
                waitCount += 2
                @textOut.concat "      "
                time = waitCount * @sTimer1 * 1.0 / @sTimer2
                @textOut.concat "Wait %d SYNC (%.3f s.)" % [waitCount, time]
                totalTime += time
            elsif cmd == 0xFD #END/LOOP
                @textOut.concat "%02x          " % cmd
                @textOut.concat "End of data"
                if @sLoopOffset != 0
                    @textOut.concat "(back to loop point at 0x%08x)" % @sLoopOffset
                end
                break
            else
                device = @sDeviceData[cmd / 2]
                if device.nil?
                    errorMsg "Invalid device at 0x08%x" % off
                end
                devInfo = @deviceInfoData[device[:sDeviceType]]

                reg = @s98File.readByte
                data = @s98File.readByte
                @textOut.concat "%02x %02x %02x    " % [cmd, reg, data]
                @textOut.concat "%s " % devInfo[:mName]
                if devInfo[:mPorts] == 2
                    @textOut.concat "port %d" % [cmd & 1]
                end
            end
            @textOut.concat "\n"
        end
    end

    def parseToFile
        sVersion = @s98File.readBytes(4).pack('c*')
        if !sVersion.to_s.start_with?("S98")
            errorMsg "Not a S98 file"
        elsif !sVersion[3].to_s.start_with?("1", "2", "3")
            errorMsg "Unsupported S98 version"
        end
        @textOut.concat "Detected S98 file, version %d\n" % sVersion[3].to_s
        parseHeaderTagData()
        parseDumpData()

        #puts @textOut
        IO.binwrite(@outFile, @textOut)
    end
end

def main()
    if ARGV.length < 1 || ARGV.length > 2
        errorMsg "Usage: s98txt.rb s98File [dumpFile]"
    end
    s98Parser = S98Parser.new(ARGV[0], ARGV[1])
    s98Parser.parseToFile
end

main
