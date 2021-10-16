class Util
  def self.CSV2hashArray(_csvFile)
    return CSV.read(_csvFile, :encoding => "utf-8", :headers => true, :col_sep => ";").map {|p| p.to_h}
  end

  def self.JIS0208_SJIS(byte1, byte2)
    sjis = [0, 0]
    # sjis[0] = ((byte1 - 1) >> 1) + ((byte1 <= 0x5e) ? 0x71 : 0xb1)
    # sjis[1] = byte2 + ((byte1 & 1) ? ((byte2 < 0x60) ? 0x1f : 0x20) : 0x7e);

    sjis[0] = ((byte1 + 1) >> 1) + ((byte1 <= 0x5e) ? 0x70 : 0xb0)
    sjis[1] = byte2 + ((byte1 % 2 == 1) ? ((byte2 < 0x60) ? 0x1f : 0x20) : 0x7e);

    return b2n(sjis, false)
  end

  def self.b2n(bytes,isLE = true)
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

  def self.n2b(num,count,isLE = true)
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




end
