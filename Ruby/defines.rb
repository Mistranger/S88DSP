require "pp"
require 'open3'
require 'fileutils'

module Paths
  MAIN_PATH = File.expand_path(__dir__ + '/..')

  Tools = MAIN_PATH + "/Tools/"
  Temp = MAIN_PATH + "/Temp/"
  Source = MAIN_PATH + "/Source/"
  Music = MAIN_PATH + "/Music/"
  S98Import = MAIN_PATH + "/S98/"
  S88Import = MAIN_PATH + "/S88/"
  Build = MAIN_PATH + "/Build/"

  AS_Path = Tools + 'as/bin'
  AS_Exe= AS_Path + '/' + 'asw.exe'
  P2bin_Exe = AS_Path + '/' + 'p2bin.exe'
  D88Saver_Exe = Tools + 'd88saver.exe'

  LZSA_Exe = Tools + 'lzsa.exe'

  D88File = Build + 'test2hdboot.d88'

  D88EXT = '.d88'

  Z80Ext = ".z80"

  FAT_File = 'fattable.bin'

  # Data files
end

module Const
  Disk_SectorSize = 0x400

end


