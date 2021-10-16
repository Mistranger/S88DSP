## S88DSP

### About

S88DSP is a music player in development for NEC PC-8801 series computers. 

This is my attempt to create an universal music player for PC-8801 computer. Unlike the existing music playing engines (like PMD or MUCOM88) which are designed to play compiled MML music, S88DSP uses dump data format similar to S98 and VGM, thus allowing to play almost any OPN/OPNA music on PC-8801 computer.  
The current implementation supports 2HD disks only (NEC PC-8801 MH and higher), support for 2D disks will be added in the future.

### Player internals
The playback core consists of 2x16KB buffers on main memory for music and 8KB on disk-SUB side for disk read buffer. Upon loading a track, both buffers are filled from floppy. During playback the core switches buffers on underrun and fetches next block of data from disk-SUB (which constantly then reloads next block from floppy).  
The playback is controlled by 1/600 timer interrupt. The playback core is fast enough to work even on 4MHz CPU.

The music format, ".S88", is a feature-reduced version of S98 but with LZSA1/LZSA2 compression support. S88 supports only OPN/OPNA chip music and thus uses only two bytes for each register/data dump instead of three in S98/VGM. The S88 file consists of a 1024-byte header (for 1024 byte sector alignment), and a series of compressed data blocks of variable size. Full specification currently available in Source/player.z80 file.

### How to prepare a music disc:

Note: The "Example" subdirectory contains some precompiled soundtracks from some PC-98 games.

The build system is written on Ruby, so if you don't have it on your system, install it first.

Get some S98 music files for conversion (if you have music in VGM format, convert it to S98 first). Only OPN/OPNA music is supported.  
Place them into "S98" subdirectory and run "conv.rb" from "Ruby" subdirectory. The "conv.rb" accepts one boolean parameter - whether to apply SSG channel volume level fix (to make songs from PC-98 have quieter SSG level).  
After running "conv.rb" script, the converted files should be available in "Music" subdirectory.  
Now choose the tracks you want to write on .d88 floppy image. Don't go over 1140 KB to fit into 2HD space limits.  
Place the desired ".s88" files in "S88" subdirectory and run "main.rb" script from "Ruby" subdirectory. If everything is done correctly, you should have "test2hdboot.d88" image file in "Build" subdirectory.  
To play the music, set this image in drive 1 and reset the PC-8801.

"Space" key advances to next track.

### History

0.1 - initial version

### Plans for the future...

GUI (so it would look like a player)  
RS-232 support (to stream music from host machine without recording on floppies)  
(maybe) S88 pre-optimization.  
2D floppy support / dual floppy support.  
