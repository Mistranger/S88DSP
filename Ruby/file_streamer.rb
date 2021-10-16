class FileStreamer
  def initialize(_file = nil, _endianness = 'LE')
    @curOffset = 0
    @endianness = _endianness
    if (_file != nil)
      self.open(_file)
    end
  end

  def b2n(bytes,isLE = true)
    num = 0
    if isLE
      counter = 0.upto((bytes.size-1)).map {|b| b}
    else
      counter = (bytes.size-1).downto(0).map {|b| b}
    end
    bytes.size.times do |t|
      num += bytes[t] << (counter[t] * 8)
    end
    return num
  end

  def n2b(num,count,isLE = true)
    bytes = Array.new
    if isLE
      counter = 0.upto((count-1)).map {|b| b}
    else
      counter = (count-1).downto(0).map {|b| b}
    end
    counter.size.times do |t|
      bytes.push ((num >> (counter[t] * 8)) & 0xff)
    end
    return bytes
  end

  def open(_file)
    @fBytes = IO.binread(_file).bytes
    @fBytes.freeze
  end

  def openMemory(_data)
    @fBytes = _data.clone
    @fBytes.freeze
  end

  def clone()
    newStream = StreamFile.new
    newStream.fBytes = self.fBytes
  end

  def getAddr(_addr)
    return _addr == -1 ? @curOffset : _addr
  end

  def restoreAddr(_addr, _curAddr)
    if _addr == -1
      @curOffset = _curAddr
    end
  end

  def eof()
    @curOffset >= @fBytes.length
  end

  def offset()
    @curOffset
  end

  def length()
    @fBytes.length
  end

  def reset(_offset = 0)
    @curOffset = _offset
  end

  def advance(_count)
    @curOffset += _count
  end

  def peek(_offset = 0, _failChar = '\0')
    if !eof
      return @fBytes[@curOffset + _offset]
    else
      return _failChar
    end
  end

  def readByte(_addr = -1)
    curAddr = getAddr(_addr)
    read = @fBytes[curAddr]
    curAddr += 1
    restoreAddr(_addr, curAddr)
    return read & 0xFF
  end

  def readWord(_addr = -1)
    curAddr = getAddr(_addr)
    read = b2n(@fBytes[curAddr, 2], @endianness == 'LE')
    curAddr += 2
    restoreAddr(_addr, curAddr)
    return read
  end

  def readLong(_addr = -1)
    curAddr = getAddr(_addr)
    read = b2n(@fBytes[curAddr, 4], @endianness == 'LE')
    curAddr += 4
    restoreAddr(_addr, curAddr)
    return read
  end

  def readBytes(count, _addr = -1)
    curAddr = getAddr(_addr)
    bytes = @fBytes[curAddr, count]
    curAddr += count
    restoreAddr(_addr, curAddr)
    return bytes
  end

  def readString(endByte = '\0', _addr = -1)
    bytes = []
    curAddr = getAddr(_addr)
    loop do
      bytes.push @fBytes[curAddr]
      curAddr += 1
      if bytes.last == endByte
        break
      end
      if curAddr >= @fBytes.length
        break
      end
    end
    restoreAddr(_addr, curAddr)
    return bytes
  end

  def fetchUntil(endByte = '\0', _addr = -1)
    bytes = []
    curAddr = getAddr(_addr)
    loop do
      if @fBytes[curAddr] == endByte
        break
      end
      bytes.push @fBytes[curAddr]
      curAddr += 1
      if curAddr >= @fBytes.length
        break
      end
    end
    restoreAddr(_addr, curAddr)
    return bytes
  end

end
