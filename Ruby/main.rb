require_relative 'defines.rb'

# Z80 player code
ASMFiles = [
    'player',
    'ipl',
    'sub'
]

# D88 image build list
D88Lines = [
    'ipl.bin" 0 0 1',
    'sub.bin" 0 1 1',
    'player.bin" 0 2 1',
]


def loadSongs
  songList = Dir.entries(Paths::S88Import).select {|s| s.include?('.s88')}

  #  start track
  fileParams = {:mDisk => 0, :mTrack => 4, :mSector => 1}
  # header
  fatTable = []
  fatTable.push 1
  fatTable.push songList.length

  30.times {fatTable.push 0}

  songList.each do |song|
    fatTable.push fileParams[:mTrack]
    fatTable.push fileParams[:mSector]
    fatTable.push 0
    fatTable.push 0
    28.times {fatTable.push 0}
    params = fileParams[:mDisk].to_s + ' ' + fileParams[:mTrack].to_s+ ' ' + fileParams[:mSector].to_s
    d88SaverCmd = '"' + Paths::D88Saver_Exe + '" "' + Paths::D88File + '" "' + Paths::S88Import + song + '" ' + params
    d88SaverCmd.gsub!('/', '\\')
    puts d88SaverCmd
    stdin, stdout, stderr, wait_thr = Open3.popen3(d88SaverCmd)
    pid = wait_thr[:pid]
    errors = stdout.read
    p errors
    nextTrack = errors.scan(/\?Trk(\d+?),/).first.first.to_i
    #p nextTrack
    nextSector = errors.scan(/\?\?Trk\d+?,Sec(\d+?)\?/).first.first.to_i
    #p nextSector
    nextSector += 1
    if nextSector >= 8
      nextTrack += 1
      nextSector = 1
    end

    fileParams[:mTrack] = nextTrack
    fileParams[:mSector] = nextSector

  end
  ((63 - songList.length) * 0x20).times {fatTable.push 0}

  IO.binwrite(Paths::Build + Paths::FAT_File, fatTable.pack('C*'))
  D88Lines.push(Paths::FAT_File + '" 0 1 2')
end

def main
  ASMFiles.each do |asm|
    asCmdLine = '"' + Paths::AS_Exe + '" -cpu z80undoc -L -olist "' + Paths::Build + asm + '.lst" -o "' + Paths::Build + asm + '.p" "' + Paths::Source + asm + Paths::Z80Ext + '"'
    asCmdLine.gsub!('/', '\\')
    puts asCmdLine
    stdin, stdout, stderr, wait_thr = Open3.popen3(asCmdLine)
    pid = wait_thr[:pid]
    errors = stderr.read
    if !errors.nil?
      if errors.empty?
        p2CmdLine = '"' + Paths::P2bin_Exe + '" "' + Paths::Build + asm + '.p" -k -l 0 -r $-$'
        p2CmdLine.gsub!('/', '\\')
        puts p2CmdLine
        stdin, stdout, stderr, wait_thr = Open3.popen3(p2CmdLine)
        pid = wait_thr[:pid]
        errors = stderr.read
        if !errors.nil?
          if errors.empty?
            puts "Successful compilation"
          else
            puts errors
            exit(1)
          end
        end
      else
        puts errors
        exit(1)
      end
    end
  end

  loadSongs

  D88Lines.each do |file|
    d88SaverCmd = '"' + Paths::D88Saver_Exe + '" "' + Paths::D88File + '" "' + Paths::Build + file
    d88SaverCmd.gsub!('/', '\\')
    puts d88SaverCmd
    stdin, stdout, stderr, wait_thr = Open3.popen3(d88SaverCmd)
    pid = wait_thr[:pid]
    errors = stdout.read
    puts errors
  end

end

main