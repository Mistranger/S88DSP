P_32_ModeSelect		 	equ $32
P_34_CRTC_ALU		 	equ $34
P_35_GVRAMControl	 	equ $35
P_40_System		 		equ $40
P_50_CRTC_Port1	 		equ $50
P_51_CRTC_Port2	 		equ $51
P_5C_Bank				equ $5C
P_5D_RedBank			equ $5D
P_5E_GreenBank			equ $5E
P_5F_MainRam			equ $5F

P_68_DMAC_0				equ $60
P_68_DMAC_1				equ $61
P_68_DMAC_2				equ $62
P_68_DMAC_3				equ $63
P_68_DMAC_4				equ $64
P_68_DMAC_5				equ $65
P_68_DMAC_6				equ $66
P_68_DMAC_7				equ $67
P_68_DMAC_Status		equ $68

P_70_TextWindowOffset 	equ $70

P_E4_IntLevel 			equ $E4

P_FD_DiskSysPortA 		equ $FC
P_FD_DiskSysPortB 		equ $FD
P_FE_DiskSysPortC 		equ $FE
P_FF_DiskSysControl		equ $FF

; 
F_32_SINTM				equ $80
F_32_GVAM				equ $40
F_32_PMODE				equ $20
F_32_TMODE				equ $10
F_32_AVC1				equ $08
F_32_AVC2				equ $04
F_32_EROMSL1			equ $02
F_32_EROMSL2			equ $01
	
F_32_Bank0				equ $00
F_32_Bank1				equ $01
F_32_Bank2				equ $02
F_32_Bank3				equ $03
F_32_TvOut				equ $00
F_32_Forbidden			equ $04
F_32_ComputerOut		equ $08
F_32_Optional			equ $0C
	
	
F_W35_GVRAMAccess		equ $80

F_R40_VRTC				equ $20

TVRAM					equ	$F3C8			;TVRAM start address

; Subsystem commands
	ENUM 		Sub00_Initialize
	NEXTENUM	Sub01_WriteData
	NEXTENUM	Sub02_ReadData
	NEXTENUM	Sub03_SendData
	NEXTENUM	Sub04_Copy
	NEXTENUM	Sub05_Format
	NEXTENUM	Sub06_SendResultStatus
	NEXTENUM	Sub07_SendDriveStatus
	NEXTENUM	Sub08_TestMemory
	NEXTENUM	Sub09_SendMemory
	NEXTENUM	Sub0A_AutoMarginSupport
	NEXTENUM	Sub0B_SendMemory2
	NEXTENUM	Sub0C_ReveiveMemory
	NEXTENUM	Sub0D_Execute
	NEXTENUM	Sub0E_LoadData
	NEXTENUM	Sub0F_SaveData
	NEXTENUM	Sub10_LoadAndGo
	NEXTENUM	Sub11_FastWriteData
	NEXTENUM	Sub12_FastSendData
	NEXTENUM	Sub13_ErrorInfo
	NEXTENUM	Sub14_DriveSense
	NEXTENUM	Sub15_FastSendMemory
	NEXTENUM	Sub16_FastReceiveMemory
	NEXTENUM	Sub17_SetSurfaceMode
	NEXTENUM	Sub18_SendSurfaceMode
	NEXTENUM	Sub19_SetReadAfterWrite
	NEXTENUM	Sub1A_ResetReadAfterWrite
	NEXTENUM	Sub1B_Resume
	NEXTENUM	Sub1C_SetBreakpoint
	NEXTENUM	Sub1D_SetRegister
	NEXTENUM	Sub1E_SendRegister
	; 2HD commands
	NEXTENUM	Sub1F_SetDiscMode
	NEXTENUM	Sub20_SendDiskMode
	NEXTENUM	Sub21_SetBoundaryMode
	NEXTENUM	Sub22_SendBoundaryMode
	NEXTENUM	Sub23_DriveReadyCheck
	NEXTENUM	Sub24_ExpandedFormat

Sub_SendCommand MACRO cmd
	ld	a, cmd
	call Disk88_sendcmd 
	ENDM

SetPort MACRO port, data
	ld	a, data
	out (port), a
	ENDM

