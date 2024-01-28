.INCLUDE "header.asm"

.SEGMENT "ZEROPAGE"

.INCLUDE "registers.inc"

; game constant

bullet1ADR = $02A8
bullet2ADR = $02AC
bullet3ADR = $02B0
bullet4ADR = $02B4

bulletAffichageADR = $0278

bigTimerADR = $02D0

STARTING_POS= $60
P1XPOS = $28
P2XPOS = $D0
STATETITLE     = $00  ; displaying title screen
STATEPLAYING   = $01  ; move cowboy move bullet, check for collisions
STATEGAMEOVER  = $02  ; displaying game over screen
STATEPLAYERDEATH=$03

BOTTOMWALLFORB = $D0
RIGHTWALLP1    = $40
LEFTWALLP1     = $02
TOPWALL        = $20
BOTTOMWALL     = $A0
RIGHTWALLP2    = $F6
LEFTWALLP2     = $B6

;variable
pointerLo: .res 1   ; pointer variables are declared in RAM
pointerHi:  .res 1   ; low byte first, high byte immediately after
buttons1: .res 1
buttons2: .res 1
timer: .res 1
timer2: .res 1
posYP1: .res 1
posYP1Width: .res 1
posXP1: .res 1
posYP2: .res 1
posYP2Width: .res 1
posXP2: .res 1
curr_sprite: .res 1
row_first_tile: .res 1
allScore1: .res 1
score1: .res 1
score1Hi: .res 1
allScore2: .res 1
score2: .res 1
score2Hi: .res 1
gamestate: .res 1
gameoverBG: .res 1
timerTitle: .res 1
timerDemo: .res 1
DemoAnimationFrame: .res 1
flip_flop: .res 1
posXDemo: .res 1
cowboyPhase: .res 1
bullet: .res 1
bullet1x: .res 1
bullet1y: .res 1
bullet2x: .res 1
bullet2y: .res 1
bullet3x: .res 1
bullet3y: .res 1
bullet4x: .res 1
bullet4y: .res 1
currentbullety: .res 1
currentbulletx: .res 1
startingAngleP1: .res 1
startingAngleP2: .res 1
angleP1bullet1: .res 1
angleP1bullet2: .res 1
angleP2bullet1: .res 1
angleP2bullet2: .res 1
currentAngle: .res 1
BCD: .res 1
velxP1: .res 1
velxP2: .res 1
velyP1: .res 1
velyP2: .res 1
nbBulletP1: .res 1
nbBulletP2: .res 1
IsPressingP1: .res 1
IsPressingP2: .res 1
P2isDead: .res 1
P1isDead: .res 1
P1animIndex: .res 1
P2animIndex: .res 1
ban: .res 1
posYB3: .res 1
posYB4: .res 1
CactusPos: .res 1
CactusPos2: .res 1
CactusPos3: .res 1

.SEGMENT "STARTUP"

RESET:
  .INCLUDE "init.asm"

.SEGMENT "CODE"

  LDA #STATEGAMEOVER
  STA gamestate
  LDA #$01
  STA gameoverBG

  JSR LoadPalette
  JSR LoadBackground
  JSR setTimer

  LDA #%10010000
  STA PPU_CTRL
  LDA #%00011110
  STA PPU_MASK

  JSR ResetPosition
  LDA #$0F
  STA APU_STATUS  ;enable Square 1, Square 2, Triangle and Noise channels.  Disable DMC.

forever:
  JMP forever

NMI:
  LDA #$00
  STA PPU_OAM_ADDR
  LDA #$02
  STA OAM_DMA

  JSR DrawScore

  LDA #%10010000
  STA PPU_CTRL
  LDA #%00011110
  STA PPU_MASK

  LDA #$00          ; no scroll
  STA PPU_SCROLL
  STA PPU_SCROLL

  ;;;all graphics updates done by PPU here
  JSR ReadController1  ;;get the current button data for player 1
  JSR ReadController2  ;;get the current button data for player 2



GameEngine:  
  LDA gamestate
  CMP #STATETITLE
  BEQ EngineTitle    ;;game is displaying title screen
    
  LDA gamestate
  CMP #STATEGAMEOVER
  BNE @continue
  JMP EngineGameOver  ;;game is displaying ending screen
  @continue:
  
  LDA gamestate
  CMP #STATEPLAYING
  BEQ EnginePlaying   ;;game is playing

  LDA gamestate
  CMP #STATEPLAYERDEATH
  BNE GameEngineDone
  JMP EngineStopForPlayerDeath
GameEngineDone:  

  RTI

EnginePlaying:
  JMP enginePlay

EngineTitle:
  LDA BCD
  CMP #$01
  BEQ jeuStateLoop
  ; initialise les variables
  LDA #$00
  STA P2isDead
  STA P1isDead
  STA angleP1bullet1
  STA angleP1bullet2
  STA angleP2bullet1
  STA angleP2bullet2
  STA currentAngle
  STA bullet
  JSR decreaseTimer
  

  LDA #$00
  STA curr_sprite 
  JSR spawnPlayer
  JSR titleMovePlayer


titleloop:  
  LDA timer2
  CMP #$01
  BEQ jeuState
  JSR decreaseTimer2
  JMP GameEngineDone
jeuState:
  JSR ShowDraw
  LDA #$01
  STA BCD
jeuStateLoop:
  JSR decreaseTimer2
  LDA timer2
  CMP #$01
  BEQ jeuStatefin
  JMP GameEngineDone
jeuStatefin:
  LDA #STATEPLAYING
  STA gamestate
  JSR setTimer
  JSR setTimer2
  JSR UnloadGo
  LDA #$00
  STA BCD
  JSR GetElementBackground
  JMP GameEngineDone

;;;;;;;;; 
 
EngineGameOver:
  LDA gameoverBG
  BEQ EndingLoop
  JSR LoadBackground2
  LDA #$00
  STA gameoverBG
  JSR ClrSprite
  LDA #$C0
  STA timerTitle
EndingLoop:

  JSR DemoTime
  LDX buttons1
  CPX #$10
  BEQ titleState
  LDA bullet
  BEQ finCheckBullet
  JSR MoveBullet
  LDA currentbullety
  STA bullet1ADR
  LDA currentbulletx
  STA bullet1ADR+3
finCheckBullet:
  JMP GameEngineDone
titleState:
  LDA #STATETITLE
  STA gamestate
  LDA #$01
  STA gameoverBG
  JSR setTimer2
  ; decharger l'écran de game over
  JSR EndDemo
  JSR UnloadBackground2
  JSR CactusMiddle
  JSR ShowReady
  LDA #$01
  STA startingAngleP1
  LDA #$11
  STA startingAngleP2
  LDA #$00
  STA score1Hi
  STA score1
  STA allScore1
  STA score2Hi
  STA score2
  STA allScore2
  JSR setBigTimer
  JMP GameEngineDone
 
;;;;;;;;;;;

enginePlay:
  LDA buttons1
  CMP #$80
  BCS @P1stillPressing
  LDA #$00
  STA IsPressingP1
@P1stillPressing:
  LDA buttons2
  CMP #$80
  BCS @P2stillPressing  
  LDA #$00
  STA IsPressingP2
@P2stillPressing:

  JSR decreaseTimer
  JSR decreaseTimer2
  JSR drawBigTimer
  JSR DrawScore
  JSR handleVelocityP1
  JSR handleVelocityP2
  JSR movePlayer
  JSR drawBullet
  JSR changeAngle
  JSR shotBullet
  JSR HandleBulletMovement
  JSR checkFlicker
  JSR checkCollision
  
checkDeath:
  LDA P1isDead
  CMP #$01
  BEQ @deathState
  LDA P2isDead
  CMP #$01
  BEQ @deathState
  JMP checkDraw
  @deathState:
    JSR setTimer2
    LDA #STATEPLAYERDEATH
    STA gamestate
    JMP GameEngineDone

checkDraw:
  LDA nbBulletP1
  BNE playLoop
  LDA nbBulletP2
  BNE playLoop
  LDA bullet
  BNE playLoop
  @deathState:
    JSR setTimer2
    LDA #STATEPLAYERDEATH
    STA gamestate
    JMP GameEngineDone
playLoop:
  LDA timerTitle
  CMP #$FF
  BEQ gameOverState
  JMP GameEngineDone
gameOverState:
  LDA #STATEGAMEOVER
  STA gamestate
  JSR UnloadBigTimer
  JSR destroyAllBullet
  LDA #$00
  STA NOISE_VOL
  STA curr_sprite
  STA cowboyPhase
  JSR ResetPosition
  LDA #$00
  STA PPU_CTRL
  STA PPU_MASK
  JSR LoadBackground
  LDA #$90
  STA PPU_CTRL
  LDA #$1E
  STA PPU_MASK
  JMP GameEngineDone

EngineStopForPlayerDeath:
  JSR decreaseTimer2
  JSR playerDead
  stopLoop:
  LDA timer2
  CMP #$01
  BEQ ToRepositionState
  JMP GameEngineDone
  ToRepositionState:
  LDA #STATETITLE
  STA gamestate
  JSR ShowReady
  JSR setTimer2
  JSR ClrSprite
  JSR ResetPosition
  LDA #$00
  STA bullet1x
  STA bullet2x
  STA bullet3x
  STA bullet4x
  JMP GameEngineDone

;----------subroutines---------------


;------------------------------------
;fonction util
;------------------------------------
VBlankWait:
  BIT PPU_STATUS
  BPL VBlankWait
  RTS

LoadPalette:
    LDA #$3F
    STA PPU_ADDRESS
    LDA #$00
    STA PPU_ADDRESS
    LDX #$00
  LoadPaletteLoop:
    LDA paletteData,x
    STA PPU_DATA
    INX
    CPX #$20
    BNE LoadPaletteLoop
    RTS

ReadController1:
    LDA #$01
    STA JOY1
    LDA #$00
    STA JOY1
    LDX #$08
  ReadController1Loop:
    LDA JOY1
    LSR A
    ROL buttons1
    DEX
    BNE ReadController1Loop
    RTS

ReadController2:
    LDA #$01
    STA JOY2_FRAME
    LDA #$00
    STA JOY2_FRAME
    LDX #$08
  ReadController2Loop:
    LDA JOY2_FRAME
    LSR A
    ROL buttons2
    DEX
    BNE ReadController2Loop
    RTS

ResetPosition:
  LDA #STARTING_POS
  STA posYP1
  STA posYP2
  LDA #STARTING_POS+19
  STA posYP1Width
  STA posYP2Width
  LDA #P1XPOS
  STA posXP1
  LDA #P2XPOS
  STA posXP2
  LDA #$00
  STA velxP1
  STA velxP2
  STA velyP1
  STA velyP2
  LDA #$06
  STA nbBulletP1
  STA nbBulletP2
  LDA #$00
  STA posXDemo
  RTS

HandleBulletMovement:
  LDX bullet
  CPX #$00
  BNE @fire
  JMP @fin
  @fire:
  LDA bullet
  AND #$0F
  CMP #$03
  BEQ @2bullet
  CMP #$01
  BEQ @1bullet
  CMP #$02
  BEQ @1bulletbutSecond
  JMP @skip
  @1bullet:
    LDA bullet1x
    STA currentbulletx
    LDA bullet1y
    STA currentbullety
    LDA angleP1bullet1
    STA currentAngle
    JSR MoveBullet
    LDA currentbulletx
    STA bullet1x
    LDA currentbullety
    STA bullet1y
    LDA currentAngle
    STA angleP1bullet1
    JMP @skip
  @2bullet:
    LDA bullet2x
    STA currentbulletx
    LDA bullet2y
    STA currentbullety
    LDA angleP1bullet2
    STA currentAngle
    JSR MoveBullet
    LDA currentbulletx
    STA bullet2x
    LDA currentbullety
    STA bullet2y
    LDA currentAngle
    STA angleP1bullet2
    LDA angleP1bullet1
    STA currentAngle
    LDA bullet1x
    STA currentbulletx
    LDA bullet1y
    STA currentbullety
    JSR MoveBullet
    LDA currentbulletx
    STA bullet1x
    LDA currentbullety
    STA bullet1y
    LDA currentAngle
    STA angleP1bullet1
    JMP @skip
  @1bulletbutSecond:
    LDA bullet2x
    STA currentbulletx
    LDA bullet2y
    STA currentbullety
    LDA angleP1bullet2
    STA currentAngle
    JSR MoveBullet
    LDA currentbulletx
    STA bullet2x
    LDA currentbullety
    STA bullet2y
    LDA currentAngle
    STA angleP1bullet2
  @skip:
    LDA bullet
    AND #$F0
    CMP #$30
    BEQ @4bullet
    CMP #$10
    BEQ @3bullet
    CMP #$20
    BEQ @1bulletbutFourth
    JMP @fin
  @3bullet:
    LDA angleP2bullet1
    STA currentAngle
    LDA bullet3x
    STA currentbulletx
    LDA bullet3y
    STA currentbullety
    JSR MoveBullet
    LDA currentbulletx
    STA bullet3x
    LDA currentbullety
    STA bullet3y
    LDA currentAngle
    STA angleP2bullet1
    JMP @fin
  @4bullet:
    LDA angleP2bullet2
    STA currentAngle
    LDA bullet4x
    STA currentbulletx
    LDA bullet4y
    STA currentbullety
    JSR MoveBullet
    LDA currentbulletx
    STA bullet4x
    LDA currentbullety
    STA bullet4y
    LDA currentAngle
    STA angleP2bullet2
    LDA angleP2bullet1
    STA currentAngle
    LDA bullet3x
    STA currentbulletx
    LDA bullet3y
    STA currentbullety
    JSR MoveBullet
    LDA currentbulletx
    STA bullet3x
    LDA currentbullety
    STA bullet3y
    LDA currentAngle
    STA angleP2bullet1
    JMP @fin
  @1bulletbutFourth:
    LDA bullet4x
    STA currentbulletx
    LDA bullet4y
    STA currentbullety
    LDA angleP2bullet2
    STA currentAngle
    JSR MoveBullet
    LDA currentbulletx
    STA bullet4x
    LDA currentbullety
    STA bullet4y
    LDA currentAngle
    STA angleP2bullet2
  @fin:
    LDA bullet1y
    STA bullet1ADR
    LDA bullet1x
    STA bullet1ADR+3
    LDA bullet2y
    STA bullet2ADR
    LDA bullet2x
    STA bullet2ADR+3
    LDA bullet3y
    STA bullet3ADR
    LDA bullet3x
    STA bullet3ADR+3
    LDA bullet4y
    STA bullet4ADR
    LDA bullet4x
    STA bullet4ADR+3
    RTS


;----------------------------------------------
; end of all util function
;----------------------------------------------

;----------------------------------------------
; Get Element Background
;----------------------------------------------
GetElementBackground:
  @checkScore1:
  LDA allScore1
  CMP #$01
  BEQ @Cactus1P1
  CMP #$02
  BEQ @Cactus2P1
  CMP #$03
  BEQ @Cactus3P1
  CMP #$04
  BEQ @Arbre1Cactus2P1
  CMP #$05
  BCS @Arbre2Cactus1P1
  JMP @checkScore2
  @Cactus1P1:
  JSR Cactus1P1
  JMP @checkScore2
  @Cactus2P1:
  JSR Cactus1P1
  JSR Cactus2P1
  JMP @checkScore2
  @Cactus3P1:
  JSR UnCactusMiddle
  JSR Cactus1P1
  JSR Cactus2P1
  JSR Cactus3P1
  JMP @checkScore2
  @Arbre1Cactus2P1:
  JSR Cactus1P1
  JSR Arbre2P1
  JSR Cactus3P1
  JMP @checkScore2
  @Arbre2Cactus1P1:
  JSR Arbre1P1
  JSR Arbre2P1
  JSR Cactus3P1
  @checkScore2:
  LDA allScore2
  CMP #$01
  BEQ @Cactus1P2
  CMP #$02
  BEQ @Cactus2P2
  CMP #$03
  BEQ @Cactus3P2
  CMP #$04
  BEQ @Arbre1Cactus2P2
  CMP #$05
  BCS @Arbre2Cactus1P2
  JMP @continue
  @Cactus1P2:
  JSR Cactus1P2
  JMP @continue
  @Cactus2P2:
  JSR Cactus1P2
  JSR Cactus2P2
  JMP @continue
  @Cactus3P2:
  JSR UnCactusMiddle
  JSR Cactus1P2
  JSR Cactus2P2
  JSR Cactus3P2
  JMP @continue
  @Arbre1Cactus2P2:
  JSR Cactus1P2
  JSR Arbre2P2
  JSR Cactus3P2
  JMP @continue
  @Arbre2Cactus1P2:
  JSR Arbre1P2
  JSR Arbre2P2
  JSR Cactus3P2
  @continue:
  RTS
;--------------------------------------------
; end of get element background
;--------------------------------------------

;-------------------------------------------------------------------------------------------------
; void demo()
;toute les fonctions qui on rapport avec l'animation de la demo pendant le game over sont ici
;-------------------------------------------------------------------------------------------------
DemoTime:
    LDA timerDemo
    BNE DemoIsRunning
    LDA timerTitle
    BEQ LauchDemo
    DEC timerTitle
    RTS
  LauchDemo:
    LDA #$00
    STA PPU_CTRL
    STA PPU_MASK
    JSR LoadBackground1
    LDA #%10010000
    STA PPU_CTRL
    LDA #%00011110
    STA PPU_MASK
    LDA #$56
    STA currentbulletx
    LDA #$7A
    STA currentbullety
    LDA #$0C
    STA currentAngle
    LDA #$FF
    STA timerDemo
  DemoIsRunning:
    JSR decreaseTimer
    LDA timer
    CMP #$01
    BEQ minusSecond
    RTS
  minusSecond:
    DEC timerDemo
    LDA timerDemo
    CMP #$F0
    BCS exitDemo
    JSR ShowInsertCoin
    JSR BeginAnimationCowboy
  exitDemo:
    RTS

  BeginAnimationCowboy:
    LDA cowboyPhase
    BNE phase2
    LDA posXDemo
    CMP #$44
    BNE avanceDemo
    INC cowboyPhase
    JMP BeginAnimationCowboy
  avanceDemo:
    CLC
    ADC #$01
    STA posXDemo
    JMP animateDemo

  phase2:
    CMP #$02
    BEQ phase3
    JMP animatePhase2

  phase3:
    JMP BeginPhase3

  animateDemo:
    LDA #$68
    STA SPRITE_ADDR
    STA SPRITE_ADDR+4
    LDA #$70
    STA SPRITE_ADDR+8
    STA SPRITE_ADDR+12
    STA SPRITE_ADDR+16
    LDA #$78
    STA SPRITE_ADDR+20
    STA SPRITE_ADDR+24
    STA SPRITE_ADDR+44
    LDA #$80
    STA SPRITE_ADDR+28
    STA SPRITE_ADDR+32
    LDA #$88
    STA SPRITE_ADDR+36
    STA SPRITE_ADDR+40
    
    LDA #$00
    LDX #$00
    LDY #$00
  @loop:
    STA SPRITE_ADDR+2,y
    INY
    INY
    INY
    INY
    INX
    CPX #$0C
    BNE @loop

  drawX_leftDemo:
    LDA flip_flop
    BNE x_right_row
    LDA posXDemo
    STA SPRITE_ADDR+3
    STA SPRITE_ADDR+11
    STA SPRITE_ADDR+23
    STA SPRITE_ADDR+31
    STA SPRITE_ADDR+39
    LDA #$01
    STA flip_flop
    JMP drawX_leftDemo
  x_right_row:
    LDA posXDemo
    CLC
    ADC #$08
    STA SPRITE_ADDR+7
    STA SPRITE_ADDR+15
    STA SPRITE_ADDR+27
    STA SPRITE_ADDR+35
    STA SPRITE_ADDR+43
    LDA posXDemo
    CLC
    ADC #$10
    STA SPRITE_ADDR+19
    STA SPRITE_ADDR+47
    LDA #$00
    STA flip_flop
    LDA #$0C
    STA SPRITE_ADDR+45

    LDA DemoAnimationFrame
    CMP #$00
    BEQ starting_pos
    CMP #$01
    BEQ middle_pos
    CMP #$02
    BEQ starting_pos
    CMP #$03
    BEQ ending_pos

  starting_pos:
    LDA #$00
    LDX #$00
    LDY #$00
  currentspritesLoop:
    STA SPRITE_ADDR+1,y
    INY
    INY
    INY
    INY
    CLC
    ADC #$01
    INX
    CPX #$09
    BNE currentspritesLoop
    LDA #$FF
    STA SPRITE_ADDR+1,Y
    INY
    INY
    INY
    INY
    STA SPRITE_ADDR+1,Y
    STA SPRITE_ADDR+17
    LDA cowboyPhase
    CMP #$02
    BEQ brasHaut
    LDA #$09
    STA SPRITE_ADDR+13
    LDA #$0B
    STA SPRITE_ADDR+25
    JMP skipbras
  brasHaut:
    LDA #$12
    STA SPRITE_ADDR+17

  skipbras:
    INC DemoAnimationFrame
    JMP exitCowboyDemo

  middle_pos:

    LDA #$0A
    STA SPRITE_ADDR+21
    LDA #$0D
    STA SPRITE_ADDR+29
    LDA #$0E
    STA SPRITE_ADDR+33
    LDA #$0F
    STA SPRITE_ADDR+37
    STA SPRITE_ADDR+41

    INC DemoAnimationFrame
    JMP exitCowboyDemo

  ending_pos:

    LDA #$0A
    STA SPRITE_ADDR+21
    LDA #$3C
    STA SPRITE_ADDR+29
    LDA #$3D
    STA SPRITE_ADDR+33
    LDA #$3E
    STA SPRITE_ADDR+37
    STA SPRITE_ADDR+41
    LDA #$00
    STA DemoAnimationFrame
    JMP exitCowboyDemo

  animatePhase2:
    LDA #$3F
    STA bullet1ADR+1
    LDA #$01
    STA bullet
    LDA currentbulletx
    CMP #$F0
    BCS gotoPhase3
  waitforDestroy:
    JMP exitCowboyDemo
  gotoPhase3:
    INC cowboyPhase
    JMP exitCowboyDemo


  BeginPhase3:
    LDA posXDemo
    STA SPRITE_ADDR+7
    STA SPRITE_ADDR+15
    STA SPRITE_ADDR+27
    STA SPRITE_ADDR+35
    STA SPRITE_ADDR+43
    CLC
    ADC #$08
    STA SPRITE_ADDR+3
    STA SPRITE_ADDR+11
    STA SPRITE_ADDR+23
    STA SPRITE_ADDR+31
    STA SPRITE_ADDR+39

    LDA posXDemo
    SEC
    SBC #$08
    STA SPRITE_ADDR+19
    STA SPRITE_ADDR+47

    LDA #$03
    STA SPRITE_ADDR+13
    LDA #$06
    STA SPRITE_ADDR+25
    LDA #$11
    STA SPRITE_ADDR+45
    LDA #$12
    STA SPRITE_ADDR+17
    LDA #$68
    STA SPRITE_ADDR+16
    LDA #$70
    STA SPRITE_ADDR+44
    LDA #$40
    LDX #$00
    LDY #$00
  currentspritesLoopRev:
    STA SPRITE_ADDR+2,y
    INY
    INY
    INY
    INY
    INX
    CPX #$0C
    BNE currentspritesLoopRev

    LDA cowboyPhase
    CMP #$02
    BNE phaseTermine
    LDA posXDemo
    CMP #$08
    BNE reculeDemo
    INC cowboyPhase
    LDA cowboyPhase
    CMP #$03
    BEQ EndDemo
    JMP BeginAnimationCowboy
  reculeDemo:
    SEC
    SBC #$01
    STA posXDemo

  animatePhase3: 
    LDA DemoAnimationFrame
    CMP #$00
    BEQ starting_posP3
    CMP #$01
    BEQ middle_posP3
    CMP #$02
    BEQ starting_posP3
    CMP #$03
    BEQ ending_posP3

  phaseTermine:
    JMP exitCowboyDemo

  starting_posP3:
    JMP starting_pos

  middle_posP3:
    JMP middle_pos

  ending_posP3:
    JMP ending_pos

  EndDemo:
    LDA #$00
    STA cowboyPhase
    STA timerDemo
    STA bullet
    LDA #$56
    STA currentbulletx
    LDA #$7A
    STA currentbullety
    JSR UnloadBackground1
    JSR ClrSprite
    JSR unloadInsertCoin
    LDA #$C0
    STA timerTitle
    LDA #$00
    STA curr_sprite

  exitCowboyDemo:
    RTS

;-------------------------------
; end of demo
;-------------------------------

;------------------------------------------------------------
; fonction pour loader des tiles sur le background
;------------------------------------------------------------
ShowReady:
    LDA #$00
    STA PPU_CTRL
    STA PPU_MASK
    LDA PPU_STATUS
    LDA #$21
    STA PPU_ADDRESS
    LDA #$00
    STA PPU_ADDRESS
    LDX #$00
  readyLoop:
    LDA ReadyText, X
    STA PPU_DATA
    INX
    CPX #$60
    BNE readyLoop
    LDA #%10010000
    STA PPU_CTRL
    LDA #%00011110
    STA PPU_MASK
    RTS

ShowDraw:
    LDA #$00
    STA PPU_CTRL
    STA PPU_MASK
    LDA PPU_STATUS
    LDA #$21
    STA PPU_ADDRESS
    LDA #$00
    STA PPU_ADDRESS
    LDX #$00
  @Loop:
    LDA DrawText, X
    STA PPU_DATA
    INX
    CPX #$60
    BNE @Loop
    LDA #%10010000
    STA PPU_CTRL
    LDA #%00011110
    STA PPU_MASK
    RTS

UnloadGo:
    LDA #$00
    STA PPU_CTRL
    STA PPU_MASK
    LDA PPU_STATUS
    LDA #$21
    STA PPU_ADDRESS
    LDA #$00
    STA PPU_ADDRESS
    LDX #$00
  unloadGoLoop:
    LDA #$FF
    STA PPU_DATA
    INX
    CPX #$60
    BNE unloadGoLoop
    LDA #%10010000
    STA PPU_CTRL
    LDA #%00011110
    STA PPU_MASK
    RTS

ShowInsertCoin:
    LDA curr_sprite
    BNE exitInsertCoin
    LDA #$00
    STA PPU_CTRL
    STA PPU_MASK
    LDA PPU_STATUS
    LDA #$23
    STA PPU_ADDRESS
    LDA #$40
    STA PPU_ADDRESS
    LDX #$00
  InsertCoinLoop:
    LDA InsertCoinText, X
    STA PPU_DATA
    INX
    CPX #$60
    BNE InsertCoinLoop
    LDA #%10010000
    STA PPU_CTRL
    LDA #%00011110
    STA PPU_MASK
    INC curr_sprite
  exitInsertCoin:
    RTS

unloadInsertCoin:
    LDA #$00
    STA PPU_CTRL
    STA PPU_MASK
    LDA PPU_STATUS
    LDA #$23
    STA PPU_ADDRESS
    LDA #$40
    STA PPU_ADDRESS
    LDX #$00
  unloadInsertCoinLoop:
    LDA #$FF
    STA PPU_DATA
    INX
    CPX #$60
    BNE unloadInsertCoinLoop
    LDA #%10010000
    STA PPU_CTRL
    LDA #%00011110
    STA PPU_MASK
    RTS

ClrSprite:
    LDA #$FF
    LDX #$00
  @loop:
    STA $0200,X
    INX
    CPX #$B8
    BNE @loop
    RTS

LoadBackground1:
    LDA #$00
    STA PPU_CTRL
    STA PPU_MASK
    LDA PPU_STATUS
    LDA #$21
    STA PPU_ADDRESS
    LDA #$00
    STA PPU_ADDRESS
    LDX #$00
  @Background1Loop:
    LDA Background1, X
    STA PPU_DATA
    INX
    CPX #$60
    BNE @Background1Loop
    LDA #%10010000
    STA PPU_CTRL
    LDA #%00011110
    STA PPU_MASK
    RTS

UnloadBackground1:
    LDA #$00
    STA PPU_CTRL
    STA PPU_MASK
    LDA PPU_STATUS
    LDA #$21
    STA PPU_ADDRESS
    LDA #$00
    STA PPU_ADDRESS
    LDX #$00
  UnloadLoop:
    LDA #$FF
    STA PPU_DATA
    INX
    CPX #$60
    BNE UnloadLoop
    LDA #%10010000
    STA PPU_CTRL
    LDA #%00011110
    STA PPU_MASK
    RTS

LoadBackground2:
    LDA #$00
    STA PPU_CTRL
    STA PPU_MASK
    LDA PPU_STATUS
    LDA #$20
    STA PPU_ADDRESS
    LDA #$00
    STA PPU_ADDRESS
    LDX #$00
  Background2Loop:
    LDA Background2, X
    STA PPU_DATA
    INX
    CPX #$60
    BNE Background2Loop
    LDA #%10010000
    STA PPU_CTRL
    LDA #%00011110
    STA PPU_MASK
    RTS

UnloadBackground2:
    LDA #$00
    STA PPU_CTRL
    STA PPU_MASK
    LDA PPU_STATUS
    LDA #$20
    STA PPU_ADDRESS
    LDA #$00
    STA PPU_ADDRESS
    LDX #$00
  UnloadBackground2Loop:
    LDA #$FF
    STA PPU_DATA
    INX
    CPX #$60
    BNE UnloadBackground2Loop
    LDA #%10010000
    STA PPU_CTRL
    LDA #%00011110
    STA PPU_MASK
    RTS

LoadBackground:
    LDA PPU_STATUS        ; read PPU status to reset the high/low latch
    LDA #$20
    STA PPU_ADDRESS       ; write the high byte of $2000 address
    LDA #$00
    STA PPU_ADDRESS       ; write the low byte of $2000 address

    LDA #<background
    STA pointerLo         ; put the low byte of the address of background into pointer
    LDA #>background
    STA pointerHi         ; put the high byte of the address into pointer
    
    LDX #$00              ; start at pointer + 0
    LDY #$00
  OutsideLoop:
    
  InsideLoop:
    LDA (pointerLo), y  ; copy one background byte from address in pointer plus Y
    STA PPU_DATA        ; this runs 256 * 4 times
    
    INY                 ; inside loop counter
    CPY #$00
    BNE InsideLoop      ; run the inside loop 256 times before continuing down
    
    INC pointerHi       ; low byte went 0 to 256, so high byte needs to be changed now
    
    INX
    CPX #$04
    BNE OutsideLoop     ; run the outside loop 256 times before continuing down
    RTS

CactusMiddle:
  LDA #$00
  STA PPU_CTRL
  STA PPU_MASK
  LDA PPU_STATUS
  LDA #$21
  STA PPU_ADDRESS
  LDA #$A0
  STA PPU_ADDRESS
  LDX #$00
  LDY #$00
  LDA #$0F
  STA CactusPos
  LDA #$10
  STA CactusPos2
  JSR LoadCactus
  RTS
UnCactusMiddle:
  LDA #$00
  STA PPU_CTRL
  STA PPU_MASK
  LDA PPU_STATUS
  LDA #$21
  STA PPU_ADDRESS
  LDA #$A0
  STA PPU_ADDRESS
  LDX #$00
  LDY #$00
  LDA #$0F
  STA CactusPos
  LDA #$10
  STA CactusPos2
  JSR UnloadCactus
  RTS

Cactus1P1:
  LDA #$00
  STA PPU_CTRL
  STA PPU_MASK
  LDA PPU_STATUS
  LDA #$20
  STA PPU_ADDRESS
  LDA #$A0
  STA PPU_ADDRESS
  LDX #$00
  LDY #$00
  LDA #$14
  STA CactusPos
  LDA #$0B
  STA CactusPos2
  JSR LoadCactus
  RTS

Cactus2P1:
  LDA #$00
  STA PPU_CTRL
  STA PPU_MASK
  LDA PPU_STATUS
  LDA #$22
  STA PPU_ADDRESS
  LDA #$60
  STA PPU_ADDRESS
  LDX #$00
  LDY #$00
  LDA #$14
  STA CactusPos
  LDA #$0B
  STA CactusPos2
  JSR LoadCactus
  RTS

Cactus1P2:
  LDA #$00
  STA PPU_CTRL
  STA PPU_MASK
  LDA PPU_STATUS
  LDA #$20
  STA PPU_ADDRESS
  LDA #$A0
  STA PPU_ADDRESS
  LDX #$00
  LDY #$00
  LDA #$0B
  STA CactusPos
  LDA #$14
  STA CactusPos2
  JSR LoadCactus
  RTS

Cactus2P2:
  LDA #$00
  STA PPU_CTRL
  STA PPU_MASK
  LDA PPU_STATUS
  LDA #$22
  STA PPU_ADDRESS
  LDA #$60
  STA PPU_ADDRESS
  LDX #$00
  LDY #$00
  LDA #$0B
  STA CactusPos
  LDA #$14
  STA CactusPos2
  JSR LoadCactus
  RTS

Arbre1P1:
  LDA #$00
  STA PPU_CTRL
  STA PPU_MASK
  LDA PPU_STATUS
  LDA #$20
  STA PPU_ADDRESS
  LDA #$A0
  STA PPU_ADDRESS
  LDX #$00
  LDY #$00
  LDA #$13
  STA CactusPos
  LDA #$0B
  STA CactusPos2
  JSR LoadArbre
  RTS

Arbre2P1:
  LDA #$00
  STA PPU_CTRL
  STA PPU_MASK
  LDA PPU_STATUS
  LDA #$22
  STA PPU_ADDRESS
  LDA #$60
  STA PPU_ADDRESS
  LDX #$00
  LDY #$00
  LDA #$13
  STA CactusPos
  LDA #$0B
  STA CactusPos2
  JSR LoadArbre
  RTS

Arbre1P2:
  LDA #$00
  STA PPU_CTRL
  STA PPU_MASK
  LDA PPU_STATUS
  LDA #$20
  STA PPU_ADDRESS
  LDA #$A0
  STA PPU_ADDRESS
  LDX #$00
  LDY #$00
  LDA #$0B
  STA CactusPos
  LDA #$13
  STA CactusPos2
  JSR LoadArbre
  RTS

Arbre2P2:
  LDA #$00
  STA PPU_CTRL
  STA PPU_MASK
  LDA PPU_STATUS
  LDA #$22
  STA PPU_ADDRESS
  LDA #$60
  STA PPU_ADDRESS
  LDX #$00
  LDY #$00
  LDA #$0B
  STA CactusPos
  LDA #$13
  STA CactusPos2
  JSR LoadArbre
  RTS

Cactus3P1:
  LDA #$00
  STA PPU_CTRL
  STA PPU_MASK
  LDA PPU_STATUS
  LDA #$21
  STA PPU_ADDRESS
  LDA #$A0
  STA PPU_ADDRESS
  LDX #$00
  LDY #$00
  LDA #$12
  STA CactusPos
  LDA #$0D
  STA CactusPos2
  JSR LoadCactus
  RTS

Cactus3P2:
  LDA #$00
  STA PPU_CTRL
  STA PPU_MASK
  LDA PPU_STATUS
  LDA #$21
  STA PPU_ADDRESS
  LDA #$A0
  STA PPU_ADDRESS
  LDX #$00
  LDY #$00
  LDA #$0D
  STA CactusPos
  LDA #$12
  STA CactusPos2
  JSR LoadCactus
  RTS
    
LoadCactus:
  @Loop:
  LDA PPU_DATA
  INX
  CPX CactusPos
  BNE @Loop
  LDX #$00
  LDA Cactus,Y
  STA PPU_DATA
  @loop2:
  LDA PPU_DATA
  INX
  CPX CactusPos2
  BNE @loop2
  LDX #$00
  INY
  CPY #$03
  BNE @Loop
  LDA #%10010000
  STA PPU_CTRL
  LDA #%00011110
  STA PPU_MASK
  RTS

UnloadCactus:
  @Loop:
  LDA PPU_DATA
  INX
  CPX CactusPos
  BNE @Loop
  LDX #$00
  LDA #$2A
  STA PPU_DATA
  @loop2:
  LDA PPU_DATA
  INX
  CPX CactusPos2
  BNE @loop2
  LDX #$00
  INY
  CPY #$03
  BNE @Loop
  LDA #%10010000
  STA PPU_CTRL
  LDA #%00011110
  STA PPU_MASK
  RTS

LoadArbre:
  @Loop:
  LDA PPU_DATA
  INX
  CPX CactusPos
  BNE @Loop
  LDX #$00
  LDA Arbre,Y
  STA PPU_DATA
  INY
  LDA Arbre,y
  STA PPU_DATA
  @loop2:
  LDA PPU_DATA
  INX
  CPX CactusPos2
  BNE @loop2
  LDX #$00
  INY
  CPY #$08
  BNE @Loop
  LDA #%10010000
  STA PPU_CTRL
  LDA #%00011110
  STA PPU_MASK
  RTS
;----------------------------------
; end of loading background
;----------------------------------

;--------------------------------------------------------------------------------
; void drawScore() 
; faire afficher le score des joueurs
;--------------------------------------------------------------------------------
DrawScore:
  LDA #$10
  STA $02F8
  STA $02F0
  LDA #$08
  STA $02E0
  STA $02E8

  LDA score1
  CMP #$0A
  BEQ @incScoreHi1
  JMP @draw1Score0To9
  @incScoreHi1:
    LDA score1Hi
    BNE @secondInc1
    INC score1Hi
  @secondInc1:
    INC score1Hi
    LDA #$00
    STA score1
  @draw1Score0To9:
    CLC
    ADC #$F0
    STA $02F9
    LDA score1
    CLC
    ADC #$E0
    STA $02E9
    
    LDA #$20
    STA $02FA
    STA $02EA
    
    LDA #$38
    STA $02FB
    STA $02EB

    LDA score1Hi
    CLC
    ADC #$EF
    STA $02F1
    LDA score1Hi
    CLC
    ADC #$DF
    STA $02E1

    LDA #$20
    STA $02F2
    STA $02E2

    LDA #$30
    STA $02F3
    STA $02E3


    LDA #$10
    STA $02FC
    STA $02F4
    LDA #$08
    STA $02EC
    STA $02E4

    LDA score2
    CMP #$0A
    BEQ @incScoreHi2
    JMP @draw2Score0To9
  @incScoreHi2:
    LDA score2Hi
    BNE @secondInc2
    INC score2Hi
  @secondInc2:
    INC score2Hi
    LDA #$00
    STA score2
  @draw2Score0To9:
    CLC
    ADC #$F0
    STA $02FD
    LDA score2
    CLC
    ADC #$E0
    STA $02ED
    
    LDA #$20
    STA $02FE
    STA $02EE
    
    LDA #$C0
    STA $02FF
    STA $02EF

    LDA score2Hi
    CLC
    ADC #$EF
    STA $02F5
    LDA score2Hi
    CLC
    ADC #$DF
    STA $02E5
    
    LDA #$20
    STA $02F6
    STA $02E6
    
    LDA #$B8
    STA $02F7
    STA $02E7
    RTS
;-------------------------------
;end of drawScore()
;-------------------------------

;------------------------------------------------------------------------------------------------------
; all timer function
; if you need a timer there a function in there for you
;------------------------------------------------------------------------------------------------------
setTimer:
  LDA #$08
  STA timer
  RTS
setBigTimer:
  LDA #$46
  STA timerTitle
  RTS

setTimer2:
  LDA #$30
  STA timer2
  RTS

decreaseTimer:
  DEC timer
  BEQ decreaseTimerHi
  RTS
decreaseTimerHi:
  JSR setTimer
  RTS

decreaseTimer2:
  DEC timer2
  BEQ decreaseTimerHi2
  RTS
decreaseTimerHi2:
  JSR setTimer2
  RTS

drawBigTimer:
    LDA timer2
    CMP #$2F
    BEQ @letgo
    JMP @fin
  @letgo:
    DEC timerTitle
    LDA timerTitle
    CMP #$FF
    BNE @BinaryCodedDecimal
    JMP @fin
  @BinaryCodedDecimal:
    LDA #$00
    STA BCD
    CLC
    LDA timerTitle
    ASL A
    ROL BCD
    ASL A
    ROL BCD
    ASL A
    ROL BCD
    LDX BCD
    CPX #$05
    BCC @skip1    ; est-ce que l'accumulateur est plus grand que 5 sinon skip
    INX
    INX
    INX
    STX BCD
  @skip1:
    ASL A
    ROL BCD
    PHA
    LDA BCD
    AND #$0F
    CMP #$05
    BCC @skip2  ; est-ce que l'accumulateur est plus grand que 5 sinon skip
    LDA BCD
    CLC
    ADC #$03
    STA BCD
  @skip2:
    PLA
    ASL A
    ROL BCD
    PHA
    LDA BCD
    AND #$0F
    CMP #$05
    BCC @skip3  ; est-ce que l'accumulateur est plus grand que 5 sinon skip
    LDA BCD
    CLC
    ADC #$03
    STA BCD
  @skip3:
    PLA
    ASL A
    ROL BCD
    PHA
    LDA BCD
    AND #$0F
    CMP #$05
    BCC @skip4  ; est-ce que l'accumulateur est plus grand que 5 sinon skip
    LDA BCD
    CLC
    ADC #$03
    STA BCD
  @skip4:
    PLA
    ASL A
    ROL BCD
    PHA
    LDA BCD
    AND #$0F
    CMP #$05
    BCC @skip5  ; est-ce que l'accumulateur est plus grand que 5 sinon skip
    LDA BCD
    CLC
    ADC #$03
    STA BCD
  @skip5:
    PLA
    ASL A
    ROL BCD
    LDA BCD
    AND #$F0
    LSR
    LSR
    LSR
    LSR
    CLC
    ADC #$E0
    STA bigTimerADR+1
    ADC #$10
    STA bigTimerADR+5
    LDA BCD
    AND #$0F
    CLC
    ADC #$E0
    STA bigTimerADR+9
    ADC #$10
    STA bigTimerADR+13
    LDA #$08
    STA bigTimerADR
    STA bigTimerADR+8
    LDA #$10
    STA bigTimerADR+4
    STA bigTimerADR+12
    LDA #$00
    STA bigTimerADR+2
    STA bigTimerADR+6
    STA bigTimerADR+10
    STA bigTimerADR+14
    LDA #$78
    STA bigTimerADR+3
    STA bigTimerADR+7
    LDA #$80
    STA bigTimerADR+11
    STA bigTimerADR+15
  @fin:
    RTS

  UnloadBigTimer:
    LDA #$FF
    LDX #$00
  @loop:
    STA bigTimerADR,X
    INX
    CPX #$10
    BNE @loop
    RTS

;-------------------------------
;end of the timer funtion
;-------------------------------

;-------------------------------------------------------------------------------------------------------
; int moveBullet()
; prend (currentbullety,currentbulletx) et fait bouger un balle à une adresse selon le nombre de balle
;-------------------------------------------------------------------------------------------------------
MoveBullet:
    LDA currentAngle
    CMP #$00
    BEQ NotMoving
    AND #$0F
    CMP #$01
    BEQ MoveStraight
    CMP #$04
    BEQ MoveBulletUp60deg
    CMP #$02
    BEQ MoveBulletUp30deg
    CMP #$0A
    BEQ MoveBulletDown330deg
    CMP #$0C
    BEQ MoveBulletDown300deg

  NotMoving:
    JMP MoveBulletDone
  MoveStraight:
    JMP MoveBulletYDone

  MoveBulletUp60deg:

    LDA currentbullety
    SEC
    SBC #$02               ;;bally position = bally - ballspeedy
    STA currentbullety

    LDA currentbullety
    CMP #TOPWALL
    BCS MoveBulletUpDone      ;;if ball y(a) > top wall(cmp), still on screen, skip next section
    LDA currentAngle
    CLC
    ADC #$08
    STA currentAngle
    JMP MoveBulletUpDone

  MoveBulletUp30deg:
    LDA flip_flop
    BEQ smallamountUp
    LDA currentbullety
    SEC
    SBC #$02               ;;bally position = bally - ballspeedy
    STA currentbullety
    LDA #$00
    STA flip_flop
    JMP amountUpdone
  smallamountUp:
    LDA #$01
    STA flip_flop
  amountUpdone:
    LDA currentbullety
    CMP #TOPWALL
    BCS MoveBulletUpDone      ;;if ball y > top wall, still on screen, skip next section
    LDA currentAngle
    CLC
    ADC #$08
    STA currentAngle
  MoveBulletUpDone:
    JMP MoveBulletYDone

  MoveBulletDown300deg:

    LDA currentbullety
    CLC
    ADC #$02               ;;bally position = bally + ballspeedy
    STA currentbullety
    LDA #$00
    STA flip_flop
    JMP amountDowndone
  smallamountDown:
    LDA #$01
    STA flip_flop
  amountDowndone:
    LDA currentbullety
    CMP #BOTTOMWALLFORB
    BCC MoveBulletDownDone      ;;if ball y < bottom wall, still on screen, skip next section
    LDA currentAngle
    SEC
    SBC #$08
    STA currentAngle
    JMP MoveBulletDownDone

  MoveBulletDown330deg:
    LDA flip_flop
    BEQ smallamountDown
    LDA currentbullety
    SEC
    SBC #$02               ;;bally position = bally - ballspeedy
    STA currentbullety

    LDA currentbullety
    CMP #BOTTOMWALL
    BCS MoveBulletDownDone      ;;if ball y > top wall, still on screen, skip next section
    LDA currentAngle
    SEC
    SBC #$08
    STA currentAngle
  MoveBulletDownDone:
  MoveBulletYDone:
    LDA currentAngle
    AND #$F0
    CMP #$10
    BEQ BulletP2
  BulletP1:
    LDA currentbulletx
    CLC
    ADC #$02
    STA currentbulletx
    CMP #$FE
    BCC dontDestroy
    JSR destroyCurrentBullet
  dontDestroy:
    JMP MoveBulletDone 
  BulletP2:
    LDA currentbulletx
    SEC
    SBC #$02
    STA currentbulletx
    CMP #$02
    BCS MoveBulletDone
    JSR destroyCurrentBullet2
  MoveBulletDone:
    RTS

destroyCurrentBullet:
  LDX #$01
  LDA bullet
  AND #$0F
  CMP #$02
  BEQ @checkSecondBullet
  CMP #$03
  BEQ @transferBullet
  LDA #$FF
  STA bullet1ADR,x
  LDA #$00
  STA currentbullety
  LDA bullet
  SEC
  SBC #$01
  STA bullet
  JMP @return
  @transferBullet:
    LDA bullet2ADR,X
    STA bullet1ADR,X
    LDA #$FF
    STA bullet2ADR,X
    LDA bullet2y
    STA currentbullety
    LDA bullet2x
    STA currentbulletx
    LDA #$00
    STA bullet2x
    STA bullet2y
    LDA bullet
    SEC
    SBC #$02
    STA bullet
    JMP @return
  @checkSecondBullet:
    LDA #$FF
    STA bullet2ADR,X
    LDA #$00
    STA currentbullety
    LDA bullet
    SEC
    SBC #$02
    STA bullet
  @return:
    RTS

destroyCurrentBullet2:
  LDX #$01
  LDA bullet
  AND #$F0
  CMP #$20
  BEQ @checkSecondBullet
  CMP #$30
  BEQ @transferBullet
  LDA #$FF
  STA bullet3ADR,x
  LDA #$00
  STA currentbullety
  LDA bullet
  SEC
  SBC #$10
  STA bullet
  JMP @return
  @transferBullet:
    LDA bullet4ADR,X
    STA bullet3ADR,X
    LDA #$FF
    STA bullet4ADR,X
    LDA bullet4y
    STA currentbullety
    LDA bullet4x
    STA currentbulletx
    LDA #$00
    STA bullet4x
    STA bullet4y
    LDA bullet
    SEC
    SBC #$20
    STA bullet
    JMP @return
  @checkSecondBullet:
    LDA #$FF
    STA bullet4ADR,X
    LDA #$00
    STA currentbullety
    LDA bullet
    SEC
    SBC #$20
    STA bullet
  @return:
    RTS

;------------------------------------------------------------------------------------------------------------------
; end of moveBullet()
;------------------------------------------------------------------------------------------------------------------

;--------------------------------------------------------------------------------------
; void spawnPlayer()
;--------------------------------------------------------------------------------------
spawnPlayer:
    LDX #$00
    LDA #$00
    STA flip_flop
    STA row_first_tile
  spawnPlayer1Loop:
    LDA curr_sprite
    CMP #$09
    BEQ @toFront
    CMP #$04
    BEQ @toHand
    CMP #$0A
    BCC @notfootSprite
    LDA cowboyPhase
    AND #$0F
    CMP #$01
    BEQ @noFoot
    LDA #$3E
    STA curr_sprite
    JMP @notfootSprite
  @noFoot:
    LDA #$40
    STA curr_sprite
    JMP @notfootSprite
  @toFront:
    JMP @frontFace
  @toHand:
    JMP @handSprite
  @notfootSprite:
    LDA posYP1
    CLC
    ADC row_first_tile
    STA SPRITE_ADDR,X
    INX
    LDA cowboyPhase
    AND #$0F
    BNE @frame1
    LDA curr_sprite
    CMP #$07
    BNE @check1
    LDA #$0D
    JMP @draw
  @check1:
    CMP #$08
    BNE @draw
    LDA timer
    CMP #$08
    BNE @skipPhase1
    LDA cowboyPhase
    CLC
    ADC #$01
    STA cowboyPhase
  @skipPhase1:
    LDA #$0E
    JMP @draw
  @frame1:
    CMP #$02
    BEQ @frame2
    LDA curr_sprite
    CMP #$07
    BNE @check2
    JMP @draw
  @check2:
    CMP #$08
    BNE @draw
    LDA timer
    CMP #$04
    BNE @skipPhase2
    LDA cowboyPhase
    CLC
    ADC #$01
    STA cowboyPhase
  @skipPhase2:
    LDA #$08
    JMP @draw
  @frame2:
    LDA curr_sprite
    CMP #$07
    BNE @check3
    LDA #$3C
    JMP @draw
  @check3:
    CMP #$08
    BNE @draw
    LDA timer
    CMP #$04
    BNE @skipPhase0
    LDA cowboyPhase
    SEC
    SBC #$02
    STA cowboyPhase
  @skipPhase0:
    LDA #$3D
    JMP @draw
  @draw:
    STA SPRITE_ADDR,X
    INX
    LDA #$00
    STA SPRITE_ADDR,X
    INX
    LDA flip_flop
    BNE @rightCote
    LDA posXP1
    STA SPRITE_ADDR,x
    INX
    INC flip_flop
    JMP @nextOAM
  @rightCote:
    LDA posXP1
    CLC
    ADC #$08
    STA SPRITE_ADDR,X
    INX
    DEC flip_flop
    LDA row_first_tile
    CLC
    ADC #$08
    STA row_first_tile
    JMP @nextOAM
  @handSprite:
    LDA posYP1
    CLC
    ADC row_first_tile
    SEC
    SBC #$08
    STA SPRITE_ADDR,X
    INX
    LDA curr_sprite
    STA SPRITE_ADDR,X
    INX
    LDA #$00
    STA SPRITE_ADDR,X
    INX
    LDA posXP1
    CLC
    ADC #$10
    STA SPRITE_ADDR,X
    INX
    JMP @nextOAM
  @frontFace:
    LDA posYP1
    CLC
    ADC row_first_tile
    SEC
    SBC #$08
    STA SPRITE_ADDR,X
    INX
    LDA #$FF
    STA SPRITE_ADDR,X
    INX
    LDA #$00
    STA SPRITE_ADDR,X
    INX
    LDA posXP1
    CLC
    ADC #$10
    STA SPRITE_ADDR,X
    INX
  @nextOAM:
    INC curr_sprite
    CPX #$30
    BEQ spawnPlayer2
    JMP spawnPlayer1Loop
  ;--------------------------------------------Player2-------------------------------------------
spawnPlayer2:
    LDA #$00
    STA flip_flop
    STA row_first_tile
    STA curr_sprite
  spawnPlayer2Loop:
    LDA curr_sprite
    CMP #$09
    BEQ @toFront
    CMP #$04
    BEQ @toHand
    CMP #$0A
    BCC @notfootSprite
    LDA cowboyPhase
    AND #$F0
    CMP #$10
    BEQ @noFoot
    LDA #$3E
    STA curr_sprite
    JMP @notfootSprite
  @noFoot:
    LDA #$40
    STA curr_sprite
    JMP @notfootSprite
  @toFront:
    JMP @frontFace
  @toHand:
    JMP @handSprite
  @notfootSprite:
    LDA posYP2
    CLC
    ADC row_first_tile
    STA SPRITE_ADDR,X
    INX
    LDA cowboyPhase
    AND #$F0
    BNE @frame1
    LDA curr_sprite
    CMP #$07
    BNE @check1
    LDA #$0D
    JMP @draw
  @check1:
    CMP #$08
    BNE @draw
    LDA timer
    CMP #$08
    BNE @skipPhase1
    LDA cowboyPhase
    CLC
    ADC #$10
    STA cowboyPhase
  @skipPhase1:
    LDA #$0E
    JMP @draw
  @frame1:
    CMP #$20
    BEQ @frame2
    LDA curr_sprite
    CMP #$07
    BNE @check2
    JMP @draw
  @check2:
    CMP #$08
    BNE @draw
    LDA timer
    CMP #$04
    BNE @skipPhase2
    LDA cowboyPhase
    CLC
    ADC #$10
    STA cowboyPhase
  @skipPhase2:
    LDA #$08
    JMP @draw
  @frame2:
    LDA curr_sprite
    CMP #$07
    BNE @check3
    LDA #$3C
    JMP @draw
  @check3:
    CMP #$08
    BNE @draw
    LDA timer
    CMP #$04
    BNE @skipPhase0
    LDA cowboyPhase
    SEC
    SBC #$20
    STA cowboyPhase
  @skipPhase0:
    LDA #$3D
    JMP @draw
  @draw:
    STA SPRITE_ADDR,X
    INX
    LDA #$40
    STA SPRITE_ADDR,X
    INX
    LDA flip_flop
    BNE @rightCote
    LDA posXP2
    STA SPRITE_ADDR,x
    INX
    INC flip_flop
    JMP @nextOAM
  @rightCote:
    LDA posXP2
    SEC
    SBC #$08
    STA SPRITE_ADDR,X
    INX
    DEC flip_flop
    LDA row_first_tile
    CLC
    ADC #$08
    STA row_first_tile
    JMP @nextOAM
  @handSprite:
    LDA posYP2
    CLC
    ADC row_first_tile
    SEC
    SBC #$08
    STA SPRITE_ADDR,X
    INX
    LDA curr_sprite
    STA SPRITE_ADDR,X
    INX
    LDA #$40
    STA SPRITE_ADDR,X
    INX
    LDA posXP2
    SEC
    SBC #$10
    STA SPRITE_ADDR,X
    INX
    JMP @nextOAM
  @frontFace:
    LDA posYP1
    CLC
    ADC row_first_tile
    SEC
    SBC #$08
    STA SPRITE_ADDR,X
    INX
    LDA #$FF
    STA SPRITE_ADDR,X
    INX
    LDA #$00
    STA SPRITE_ADDR,X
    INX
    LDA posXP1
    CLC
    ADC #$10
    STA SPRITE_ADDR,X
    INX
  @nextOAM:
    INC curr_sprite
    CPX #$60
    BEQ spawnEnd
    JMP spawnPlayer2Loop
  spawnEnd:
    RTS

titleMovePlayer:
    LDA timer
    CMP #$08
    BEQ @letgo
    CMP #$04
    BNE @fin
  @letgo:
    LDA posXP1
    CLC 
    ADC #$01
    STA posXP1
    LDA posXP2
    SEC
    SBC #$01
    STA posXP2
  @fin:
    RTS

;---------------------------------------------
; end of player in title()
;---------------------------------------------

;-----------------------------------------------------------------------------
; void movePlayer()
; fonction pour dessiner les joueurs
;-----------------------------------------------------------------------------
movePlayer:
  LDA velxP1
  BNE @ismoving
  LDA velyP1
  BNE @ismoving
  LDX #$00
  LDY #$01
  LDA startingAngleP1
  CMP #$01
  BEQ @drawPlayer1IdleS
  CMP #$02
  BEQ @drawPlayer1Idle30
  CMP #$04
  BEQ @drawPlayer1Idle60
  CMP #$0A
  BEQ @drawPlayer1Idle330
  CMP #$0C
  BEQ @drawPlayer1Idle300
  JMP @drawPlayer1IdleS
  @ismoving:
    JMP movementP1
  @drawPlayer1IdleS:
    LDA Player,X
    STA SPRITE_ADDR,Y
    INX
    INY
    INY
    INY
    INY
    CPX #$0F
    BNE @drawPlayer1IdleS
    JMP skip_anim
  @drawPlayer1Idle30:
    LDA Player30deg,X
    STA SPRITE_ADDR,Y
    INX
    INY
    INY
    INY
    INY
    CPX #$0F
    BNE @drawPlayer1Idle30
    JMP skip_anim
  @drawPlayer1Idle60:
    LDA Player60deg,X
    STA SPRITE_ADDR,Y
    INX
    INY
    INY
    INY
    INY
    CPX #$0F
    BNE @drawPlayer1Idle60
    JMP skip_anim
  @drawPlayer1Idle330:
    LDA Player330deg,X
    STA SPRITE_ADDR,Y
    INX
    INY
    INY
    INY
    INY
    CPX #$0F
    BNE @drawPlayer1Idle330
    JMP skip_anim
  @drawPlayer1Idle300:
    LDA Player300deg,X
    STA SPRITE_ADDR,Y
    INX
    INY
    INY
    INY
    INY
    CPX #$0F
    BNE @drawPlayer1Idle300
    JMP skip_anim
  movementP1:
    LDA timer
    CMP #$08
    BEQ @anim
    JMP skip_anim
  @anim:
    LDX P1animIndex
    LDY #$25
    @drawPlayerWalk:
      LDA PlayerAnim,X
      STA SPRITE_ADDR,Y
      INY
      INY
      INY
      INY
      INX
      CPY #$3D
      BNE @drawPlayerWalk
      STX P1animIndex
      LDA P1animIndex
      CMP #$18
      BEQ @returnIndex
      JMP skip_anim
    @returnIndex:
      LDA #$00
      STA P1animIndex
  skip_anim:
    LDA posYP1
    CLC
    ADC velyP1
    CMP #BOTTOMWALL
    BCS @finUpdatePosY
    CMP #TOPWALL
    BCC @finUpdatePosY
    STA posYP1
  @finUpdatePosY:
    LDA posXP1
    CLC
    ADC velxP1
    CMP #RIGHTWALLP1
    BCS @finUpdatePosX
    CMP #LEFTWALLP1
    BCC @finUpdatePosX
    STA posXP1
  @finUpdatePosX:
    LDA #$00
    STA row_first_tile
    STA flip_flop
    LDY #$00
  @posLoop:
    LDA posYP1
    CLC
    ADC row_first_tile
    STA SPRITE_ADDR,Y
    INY
    INY
    LDA #$00
    STA SPRITE_ADDR,Y
    INY
    LDA flip_flop
    BNE @Rangee2
    LDA #$01
    STA flip_flop
    LDA posXP1
    STA SPRITE_ADDR,Y
    INY
    JMP @nextOAM
  @Rangee2:
    CMP #$02
    BEQ @Rangee3
    LDA #$02
    STA flip_flop
    LDA posXP1
    CLC
    ADC #$08
    STA SPRITE_ADDR,Y
    INY
    JMP @nextOAM
  @Rangee3:
    LDA posXP1
    CLC
    ADC #$10
    STA SPRITE_ADDR,Y
    INY
    LDA #$00
    STA flip_flop
    LDA row_first_tile
    CLC
    ADC #$08
    STA row_first_tile
  @nextOAM:
    CPY #$3C
    BNE @posLoop
    ;----------
    ;----------
    LDA velxP2
    BNE @ismoving
    LDA velyP2
    BNE @ismoving
    LDX #$00
    LDY #$3D
    LDA startingAngleP2
    CMP #$11
    BEQ @drawPlayer2IdleS
    CMP #$12
    BEQ @drawPlayer2Idle30
    CMP #$14
    BEQ @drawPlayer2Idle60
    CMP #$1A
    BEQ @drawPlayer2Idle330
    CMP #$1C
    BEQ @drawPlayer2Idle300
    JMP @drawPlayer2IdleS
  @ismoving:
    JMP movementP2
  @drawPlayer2IdleS:
    LDA Player,X
    STA SPRITE_ADDR,Y
    INX
    INY
    INY
    INY
    INY
    CPX #$0F
    BNE @drawPlayer2IdleS
    JMP skip_anim2
  @drawPlayer2Idle30:
    LDA Player30deg,X
    STA SPRITE_ADDR,Y
    INX
    INY
    INY
    INY
    INY
    CPX #$0F
    BNE @drawPlayer2Idle30
    JMP skip_anim2
  @drawPlayer2Idle60:
    LDA Player60deg,X
    STA SPRITE_ADDR,Y
    INX
    INY
    INY
    INY
    INY
    CPX #$0F
    BNE @drawPlayer2Idle60
    JMP skip_anim2
  @drawPlayer2Idle330:
    LDA Player330deg,X
    STA SPRITE_ADDR,Y
    INX
    INY
    INY
    INY
    INY
    CPX #$0F
    BNE @drawPlayer2Idle330
    JMP skip_anim2
  @drawPlayer2Idle300:
    LDA Player300deg,X
    STA SPRITE_ADDR,Y
    INX
    INY
    INY
    INY
    INY
    CPX #$0F
    BNE @drawPlayer2Idle300
    JMP skip_anim2
  movementP2:
    LDA timer
    CMP #$08
    BEQ @anim
    JMP skip_anim2
  @anim:
    LDX P2animIndex
    LDY #$61
    @drawPlayerWalk:
      LDA PlayerAnim,X
      STA SPRITE_ADDR,Y
      INY
      INY
      INY
      INY
      INX
      CPY #$79
      BNE @drawPlayerWalk
      STX P2animIndex
      LDA P2animIndex
      CMP #$18
      BEQ @returnIndex
      JMP skip_anim2
    @returnIndex:
      LDA #$00
      STA P2animIndex
  skip_anim2:
    LDA posYP2
    CLC
    ADC velyP2
    CMP #BOTTOMWALL
    BCS @finUpdatePosY
    CMP #TOPWALL
    BCC @finUpdatePosY
    STA posYP2
  @finUpdatePosY:
    LDA posXP2
    CLC
    ADC velxP2
    CMP #RIGHTWALLP2
    BCS @finUpdatePosX
    CMP #LEFTWALLP2
    BCC @finUpdatePosX
    STA posXP2
  @finUpdatePosX:
    LDY #$3C
    LDA #$00
    STA row_first_tile
    STA flip_flop
  @posLoop:
    LDA posYP2
    CLC
    ADC row_first_tile
    STA SPRITE_ADDR,Y
    INY
    INY
    LDA #$40
    STA SPRITE_ADDR,Y
    INY
    LDA flip_flop
    BNE @Rangee2
    LDA #$01
    STA flip_flop
    LDA posXP2
    STA SPRITE_ADDR,Y
    INY
    JMP @nextOAM
  @Rangee2:
    CMP #$02
    BEQ @Rangee3
    LDA #$02
    STA flip_flop
    LDA posXP2
    SEC
    SBC #$08
    STA SPRITE_ADDR,Y
    INY
    JMP @nextOAM
  @Rangee3:
    LDA posXP2
    SEC
    SBC #$10
    STA SPRITE_ADDR,Y
    INY
    LDA #$00
    STA flip_flop
    LDA row_first_tile
    CLC
    ADC #$08
    STA row_first_tile
  @nextOAM:
    CPY #$78
    BNE @posLoop
  @fin:
    RTS
;-------------------------------------
; end of movePlayer()
;-------------------------------------

;-----------------------------------------------------------------------------
; void shotBullet()
; fonction qui tire des balles si le joueur a appuyé sur A
;-----------------------------------------------------------------------------
shotBullet:
  LDA #$00
  STA NOISE_VOL
  LDA buttons1
  CMP #$80
  BEQ @continue
  JMP shotBulletP2
  @continue:
    LDA bullet
    AND #$0F
    CMP #$03
    BNE @notfull
    JMP shotBulletP2
  @notfull:
    LDA startingAngleP1
    CMP #$01
    BEQ @balleIsStraight
    CMP #$02
    BEQ @balleIs30deg
    CMP #$04
    BEQ @balleIs60deg
    CMP #$0A
    BEQ @balleIs330deg
    CMP #$0C
    BEQ @balleIs300deg
    JMP shotBulletP2
  @balleIs30deg:
    LDA #$08
    STA pointerHi
    LDA #$10
    STA pointerLo
    JMP @checkForMaxBullet
  @balleIs60deg:
    LDA #$08
    STA pointerHi
    LDA #$10
    STA pointerLo
    JMP @checkForMaxBullet
  @balleIs330deg:
    LDA #$10
    STA pointerHi
    LDA #$10
    STA pointerLo
    JMP @checkForMaxBullet
  @balleIs300deg:
    LDA #$10
    STA pointerHi
    LDA #$10
    STA pointerLo
    JMP @checkForMaxBullet
  @balleIsStraight:
    LDA #$08
    STA pointerHi
    LDA #$10
    STA pointerLo
  @checkForMaxBullet:
    LDA nbBulletP1
    BEQ @jk
    LDA bullet
    AND #$0F
    CMP #$01
    BEQ @secondInstance
    LDA bullet1y
    BEQ @instanciate
  @jk:
    JMP shotBulletP2
  @instanciate:
    LDA #$22
    STA NOISE_VOL
    INC bullet
    LDA startingAngleP1
    STA angleP1bullet1
    LDA posYP1
    CLC
    ADC pointerHi
    STA bullet1y
    STA posYP1Width
    LDA posXP1
    CLC
    ADC pointerLo
    STA bullet1x
    LDA #$3F
    STA bullet1ADR+1
    LDA #$00
    STA bullet1ADR+2
    DEC nbBulletP1
    LDA #$01
    STA IsPressingP1
    LDA #$08              ;$0008 is a F8# in NTSC mode
    STA NOISE_LO          ;low 8 bits of period
    LDA #$00
    STA NOISE_HI          ;high 3 bits of period
    JMP shotBulletP2
  @secondInstance:
    LDA #$22
    STA NOISE_VOL
    LDA IsPressingP1
    BNE shotBulletP2
    INC bullet
    INC bullet
    LDA startingAngleP1
    STA angleP1bullet2
    LDA posYP1
    CLC
    ADC pointerHi
    STA bullet2y
    STA posYP2Width
    LDA posXP1
    CLC
    ADC pointerLo
    STA bullet2x
    LDA #$3F
    STA bullet2ADR+1
    LDA #$00
    STA bullet2ADR+2
    LDA #$08              ;$0008 is a F8# in NTSC mode
    STA NOISE_LO          ;low 8 bits of period
    LDA #$00
    STA NOISE_HI          ;high 3 bits of period
    DEC nbBulletP1
    JMP shotBulletP2
  shotBulletP2:
    LDA buttons2
    CMP #$80
    BEQ @continue
    JMP @fin
  @continue:
    LDA bullet
    AND #$F0
    CMP #$30
    BNE @notfull
    JMP @fin
  @notfull:
    LDA startingAngleP2
    CMP #$11
    BEQ @balleIsStraight
    CMP #$12
    BEQ @balleIs30deg
    CMP #$14
    BEQ @balleIs60deg
    CMP #$1A
    BEQ @balleIs330deg
    CMP #$1C
    BEQ @balleIs300deg
    JMP @fin 
  @balleIs30deg:
    LDA #$08
    STA pointerHi
    LDA #$10
    STA pointerLo
    JMP @checkForMaxBullet
  @balleIs60deg:
    LDA #$08
    STA pointerHi
    LDA #$10
    STA pointerLo
    JMP @checkForMaxBullet
  @balleIs330deg:
    LDA #$10
    STA pointerHi
    LDA #$10
    STA pointerLo
    JMP @checkForMaxBullet
  @balleIs300deg:
    LDA #$10
    STA pointerHi
    LDA #$10
    STA pointerLo
    JMP @checkForMaxBullet
  @balleIsStraight:
    LDA #$08
    STA pointerHi
    LDA #$10
    STA pointerLo
  @checkForMaxBullet:
    LDA nbBulletP2
    BNE @continue2
    JMP @fin
  @continue2:
    LDA bullet
    AND #$F0
    CMP #$10
    BEQ @secondInstance
    LDA bullet3y
    BEQ @instanciate
    JMP @fin
  @instanciate:
    LDA #$22
    STA NOISE_VOL
    LDA bullet
    CLC
    ADC #$10
    STA bullet
    LDA startingAngleP2
    STA angleP2bullet1
    LDA posYP2
    CLC
    ADC #$08
    STA bullet3y
    STA posYB3
    LDA posXP2
    SEC
    SBC #$10
    STA bullet3x
    LDA #$3F
    STA bullet3ADR+1
    LDA #$00
    STA bullet3ADR+2
    DEC nbBulletP2
    LDA #$01
    STA IsPressingP2
    LDA #$08              ;$0008 is a F8# in NTSC mode
    STA NOISE_LO          ;low 8 bits of period
    LDA #$00
    STA NOISE_HI          ;high 3 bits of period
    JMP @fin
  @secondInstance:
    LDA #$22
    STA NOISE_VOL
    LDA IsPressingP2
    BNE @fin
    LDA bullet
    CLC
    ADC #$20
    STA bullet
    LDA startingAngleP2
    STA angleP2bullet2
    LDA posYP2
    CLC
    ADC #$08
    STA bullet4y
    STA posYB4
    LDA posXP2
    SEC
    SBC #$10
    STA bullet4x
    LDA #$3F
    STA bullet4ADR+1
    LDA #$00
    STA bullet4ADR+2
    LDA #$08              ;$0008 is a F8# in NTSC mode
    STA NOISE_LO          ;low 8 bits of period
    LDA #$00
    STA NOISE_HI          ;high 3 bits of period
    DEC nbBulletP2
  @fin:
    RTS
;-------------------------------------
; end of shotBullet()
;-------------------------------------

;-----------------------------------------------------------------------------
; void changeAngle()
; fonction qui change l'angle du bras si on appuis sur B et UP ou DOWN
;-----------------------------------------------------------------------------
changeAngle:
  LDA buttons1
  AND #$F0
  CMP #$40
  BEQ @continue
  JMP changeAngleP2
  @continue:
    LDA buttons1
    CMP #$48
    BNE @check_down
    LDA startingAngleP1
    CMP #$0C
    BEQ @300To330
    CMP #$0A
    BEQ @330To0
    CMP #$01
    BEQ @0To30
    CMP #$02
    BEQ @30To60
    JMP @check_down
  @300To330:
    LDA #$0A
    STA startingAngleP1
    JMP changeAngleP2
  @330To0:
    LDA #$01
    STA startingAngleP1
    JMP changeAngleP2
  @0To30:
    LDA #$02
    STA startingAngleP1
    JMP changeAngleP2
  @30To60:
    LDA #$04
    STA startingAngleP1
    JMP changeAngleP2
  @check_down:
    LDA buttons1
    CMP #$44
    BNE changeAngleP2
    LDA startingAngleP1
    CMP #$04
    BEQ @60To30
    CMP #$02
    BEQ @30To0
    CMP #$01
    BEQ @0To330
    CMP #$0A
    BEQ @330To300
    JMP changeAngleP2
  @60To30:
    LDA #$02
    STA startingAngleP1
    JMP changeAngleP2
  @30To0:
    LDA #$01
    STA startingAngleP1
    JMP changeAngleP2
  @0To330:
    LDA #$0A
    STA startingAngleP1
    JMP changeAngleP2
  @330To300:
    LDA #$0C
    STA startingAngleP1
    JMP changeAngleP2
  changeAngleP2:
  LDA buttons2
  AND #$F0
  CMP #$40
  BEQ @continue
  JMP @fin
  @continue:
    LDA buttons2
    CMP #$48
    BNE @check_down
    LDA startingAngleP2
    CMP #$1C
    BEQ @300To330
    CMP #$1A
    BEQ @330To0
    CMP #$11
    BEQ @0To30
    CMP #$12
    BEQ @30To60
    JMP @check_down
  @300To330:
    LDA #$1A
    STA startingAngleP2
    JMP @fin
  @330To0:
    LDA #$11
    STA startingAngleP2
    JMP @fin
  @0To30:
    LDA #$12
    STA startingAngleP2
    JMP @fin
  @30To60:
    LDA #$14
    STA startingAngleP2
    JMP @fin
  @check_down:
    LDA buttons2
    CMP #$44
    BNE @fin
    LDA startingAngleP2
    CMP #$14
    BEQ @60To30
    CMP #$12
    BEQ @30To0
    CMP #$11
    BEQ @0To330
    CMP #$1A
    BEQ @330To300
    JMP @fin
  @60To30:
    LDA #$12
    STA startingAngleP2
    JMP @fin
  @30To0:
    LDA #$11
    STA startingAngleP2
    JMP @fin
  @0To330:
    LDA #$1A
    STA startingAngleP2
    JMP @fin
  @330To300:
    LDA #$1C
    STA startingAngleP2
    JMP @fin
  @fin:
    RTS
;-------------------------------------
; end of changeAngle()
;-------------------------------------

;-----------------------------------------------------------------------------
; void drawBullet()
; fonction qui dessine les balles selon le nombre qui reste
;-----------------------------------------------------------------------------
drawBullet:
  LDA nbBulletP1
  CMP #$FF
  BEQ drawBullet2
  TAX
  LDY #$00
  LDA #$10
  STA posXDemo
  @loopP1:
    CPX #$00
    BEQ @theRest
    LDA #$D0
    STA bulletAffichageADR,Y
    INY
    LDA #$2C
    STA bulletAffichageADR,Y
    INY
    LDA #$00
    STA bulletAffichageADR,Y
    INY
    LDA posXDemo
    STA bulletAffichageADR,Y
    INY
    CLC
    ADC #$08
    STA posXDemo
    DEX
    JMP @loopP1
  @theRest:
    CPY #$18
    BEQ drawBullet2
    @loopRedraw:
      LDA #$FF
      STA bulletAffichageADR,Y
      INY
      CPY #$18
      BNE @loopRedraw
  drawBullet2:
    LDA nbBulletP2
    CMP #$FF
    BEQ @fin
    TAX
    LDA #$F0
    STA posXDemo
    LDY #$18
  @loopP2:
    CPX #$00
    BEQ @theRest
    LDA #$D8
    STA bulletAffichageADR,Y
    INY
    LDA #$2C
    STA bulletAffichageADR,Y
    INY
    LDA #$00
    STA bulletAffichageADR,Y
    INY
    LDA posXDemo
    STA bulletAffichageADR,Y
    INY
    SEC
    SBC #$08
    STA posXDemo
    DEX
    JMP @loopP2
  @theRest:
    CPY #$30
    BEQ @fin
    @loopRedraw:
      LDA #$FF
      STA bulletAffichageADR,Y
      INY
      CPY #$30
      BNE @loopRedraw
  @fin:
    RTS
;-------------------------------------
; end of drawBullet()
;-------------------------------------

;-----------------------------------------------------------------------------
; void handleVelocity()
; fonction pour augmenter ou décrémenter la position
;-----------------------------------------------------------------------------
handleVelocityP1:
  LDA buttons1
  CMP #$04
  BEQ @augVElY
  CMP #$08
  BEQ @dimVELY
  CMP #$01
  BEQ @augVElX
  CMP #$02
  BEQ @dimVELX
  JMP @freinVEL
  @augVElY:
    LDA velyP1
    CMP #$02
    BEQ @doneAugY
    CLC
    ADC #$01
    STA velyP1
  @doneAugY:
    JMP @fin
  @dimVELY:
    LDA velyP1
    CMP #$FE
    BEQ @doneDimY
    SEC
    SBC #$01
    STA velyP1
  @doneDimY:
    JMP @fin
  @augVElX:
    LDA velxP1
    CMP #$02
    BEQ @doneAugX
    CLC
    ADC #$01
    STA velxP1
  @doneAugX:
    JMP @fin
  @dimVELX:
    LDA velxP1
    CMP #$FE
    BEQ @doneDimX
    SEC
    SBC #$01
    STA velxP1
  @doneDimX:
    JMP @fin
  @freinVEL:
    LDA velyP1
    CMP #$00
    BEQ @x_frein
    CMP #$FD
    BCS @y_freinplus
    SEC
    SBC #$01
    STA velyP1
    JMP @x_frein
  @y_freinplus:
    CLC
    ADC #$01
    STA velyP1
  @x_frein:
    LDA velxP1
    CMP #$00
    BEQ @fin
    CMP #$FD
    BCS @x_freinplus
    SEC
    SBC #$01
    STA velxP1
    JMP @fin
  @x_freinplus:
    CLC
    ADC #$01
    STA velxP1 
  @fin:
    RTS

handleVelocityP2:
  LDA buttons2
  CMP #$04
  BEQ @augVElY
  CMP #$08
  BEQ @dimVELY
  CMP #$01
  BEQ @augVElX
  CMP #$02
  BEQ @dimVELX
  JMP @freinVEL
  @augVElY:
    LDA velyP2
    CMP #$02
    BEQ @doneAugY
    CLC
    ADC #$01
    STA velyP2
  @doneAugY:
    JMP @fin
  @dimVELY:
    LDA velyP2
    CMP #$FE
    BEQ @doneDimY
    SEC
    SBC #$01
    STA velyP2
  @doneDimY:
    JMP @fin
  @augVElX:
    LDA velxP2
    CMP #$02
    BEQ @doneAugX
    CLC
    ADC #$01
    STA velxP2
  @doneAugX:
    JMP @fin
  @dimVELX:
    LDA velxP2
    CMP #$FE
    BEQ @doneDimX
    SEC
    SBC #$01
    STA velxP2
  @doneDimX:
    JMP @fin
  @freinVEL:
    LDA velyP2
    CMP #$00
    BEQ @x_frein
    CMP #$FD
    BCS @y_freinplus
    SEC
    SBC #$01
    STA velyP2
    JMP @x_frein
  @y_freinplus:
    CLC
    ADC #$01
    STA velyP2
  @x_frein:
    LDA velxP2
    CMP #$00
    BEQ @fin
    CMP #$FD
    BCS @x_freinplus
    SEC
    SBC #$01
    STA velxP2
    JMP @fin
  @x_freinplus:
    CLC
    ADC #$01
    STA velxP2 
  @fin:
    RTS
;-------------------------------------
; end of handleVelocity()
;-------------------------------------

;-----------------------------------------------------------------------------
; void checkFlicker()
; fonction qui regarde le nombre de balle et les met derrière le bg si nécessaire
;-----------------------------------------------------------------------------
checkFlicker:
  LDA bullet
  CMP #$33
  BEQ @AllBullet
  CMP #$13
  BEQ @flickerP1
  CMP #$31
  BEQ @flickerP1
  JMP @fin
  @AllBullet:
    LDA ban
    CMP #$01
    BEQ @banB2andB4
    LDA posYP2Width
    STA bullet2y
    LDA posYB4
    STA bullet4y
    LDA #$00
    STA bullet1y
    STA bullet3y
    LDA #$01
    STA ban
    JMP @fin
  @banB2andB4:
    LDA posYP1Width
    STA bullet1y
    LDA posYB3
    STA bullet3y
    LDA #$00
    STA bullet2y
    STA bullet4y
    LDA #$00
    STA ban
    JMP @fin
  @flickerP1:
    LDA ban
    CMP #$01
    BEQ @banB2
    LDA posYP2Width
    STA bullet2y
    LDA #$00
    STA bullet1y
    LDA #$01
    STA ban
    JMP @fin
  @banB2:
    LDA posYP1Width
    STA bullet1y
    LDA #$00
    STA bullet2y
    LDA #$00
    STA ban
    JMP @fin
    
  @fin:
    RTS
;-------------------------------------
; end of checkFlicker()
;-------------------------------------

;-----------------------------------------------------------------------------
; void checkCollision()
; fonction qui check si la balle est entré en collision avec un des player
; on veut que le player meurt  
;-----------------------------------------------------------------------------
checkCollision:

  LDA posYP2
  SEC
  SBC #$05
  CMP bullet1y
  BCS @noCollisionP2forb1
  CLC
  ADC #$20
  CMP bullet1y
  BCC @noCollisionP2forb1
  LDA posXP2
  CMP bullet1x
  BCC @noCollisionP2forb1
  SEC
  SBC #$10
  CMP bullet1x
  BCS @noCollisionP2forb1
  ;;collision for player2 with the first bullet
  JSR destroyAllBullet
  LDA #$22
  STA NOISE_VOL
  LDA #$15              ;$0015 is a D7# in NTSC mode
  STA NOISE_LO          ;low 8 bits of period
  LDA #$00
  STA NOISE_HI          ;high 3 bits of period
  LDA #$01
  STA P2isDead
  INC score1
  INC allScore1
  JMP @noCollisionP2
  @noCollisionP2forb1:
    LDA posYP2
    CMP bullet2y
    BCS @noCollisionP2
    CLC
    ADC #$20
    CMP bullet2y
    BCC @noCollisionP2
    LDA posXP2
    CMP bullet2x
    BCC @noCollisionP2
    SEC
    SBC #$10
    CMP bullet2x
    BCS @noCollisionP2
    ;;collision for player2 with the second bullet
    JSR destroyAllBullet
    LDA #$22
    STA NOISE_VOL
    LDA #$15              ;$0015 is a D7# in NTSC mode
    STA NOISE_LO          ;low 8 bits of period
    LDA #$00
    STA NOISE_HI          ;high 3 bits of period
    LDA #$01
    STA P2isDead
    INC score1
    INC allScore1
  @noCollisionP2:
    LDA posYP1
    SEC
    SBC #$05
    CMP bullet3y
    BCS @noCollisionP1forb3
    CLC
    ADC #$20
    CMP bullet3y
    BCC @noCollisionP1forb3
    LDA posXP1
    CMP bullet3x
    BCS @noCollisionP1forb3
    CLC
    ADC #$10
    CMP bullet3x
    BCC @noCollisionP1forb3
    ;;collision for player1 with the third bullet
    JSR destroyAllBullet
    LDA #$22
    STA NOISE_VOL
    LDA #$15              ;$0015 is a D7# in NTSC mode
    STA NOISE_LO          ;low 8 bits of period
    LDA #$00
    STA NOISE_HI          ;high 3 bits of period
    LDA #$01
    STA P1isDead
    INC score2
    INC allScore2
    JMP @fin
  @noCollisionP1forb3:
    LDA posYP2
    CMP bullet2y
    BCS @noCollisionP1
    CLC
    ADC #$20
    CMP bullet2y
    BCS @noCollisionP1
    LDA posXP2
    CMP bullet2x
    BCC @noCollisionP1
    CLC
    ADC #$10
    BCC @noCollisionP1
    ;;collision for player1 with the fourth bullet
    JSR destroyAllBullet
    LDA #$22
    STA NOISE_VOL
    LDA #$15              ;$0015 is a D7# in NTSC mode
    STA NOISE_LO          ;low 8 bits of period
    LDA #$00
    STA NOISE_HI          ;high 3 bits of period
    LDA #$01
    STA P2isDead
    INC score2
    INC allScore2
    JMP @fin
  @noCollisionP1:
  @fin:
    RTS

destroyAllBullet:
  LDA bullet
  AND #$0F
  CMP #$03
  BEQ @b1Andb2Destroy
  CMP #$02
  BEQ @b2Destroy
  CMP #$01
  BEQ @b1Destroy
  JMP bulletOfPlayer2
  @b1Andb2Destroy:
    LDA bullet2y
    STA currentbullety
    JSR destroyCurrentBullet
    LDA currentbullety
    STA bullet2y
    LDA bullet1y
    STA currentbullety
    JSR destroyCurrentBullet
    LDA currentbullety
    STA bullet1y
    JMP bulletOfPlayer2
  @b2Destroy:
    LDA bullet2y
    STA currentbullety
    JSR destroyCurrentBullet
    LDA currentbullety
    STA bullet2y
    JMP bulletOfPlayer2
  @b1Destroy:
    LDA bullet1y
    STA currentbullety
    JSR destroyCurrentBullet
    LDA currentbullety
    STA bullet1y
  bulletOfPlayer2:
  LDA bullet
  AND #$F0
  CMP #$30
  BEQ @b3Andb4Destroy
  CMP #$20
  BEQ @b4Destroy
  CMP #$10
  BEQ @b3Destroy
  JMP @fin
  @b3Andb4Destroy:
    LDA bullet4y
    STA currentbullety
    JSR destroyCurrentBullet2
    LDA currentbullety
    STA bullet4y
    LDA bullet3y
    STA currentbullety
    JSR destroyCurrentBullet2
    LDA currentbullety
    STA bullet3y
    JMP @fin
  @b4Destroy:
    LDA bullet4y
    STA currentbullety
    JSR destroyCurrentBullet2
    LDA currentbullety
    STA bullet4y
    JMP @fin
  @b3Destroy:
    LDA bullet3y
    STA currentbullety
    JSR destroyCurrentBullet
    LDA currentbullety
    STA bullet3y
  @fin:
    RTS
;-------------------------------------
; end of checkCollision()
;-------------------------------------

;-----------------------------------------------------------------------------
; void playerDead()
; fonction qui dessine la mort du player qui s'est fait tirer
;-----------------------------------------------------------------------------
playerDead:
  LDA #$00
  STA NOISE_VOL
  LDA P1isDead
  CMP #$01
  BEQ DrawDeadP1
  LDA P2isDead
  CMP #$01
  BEQ @goToDrawP2
  JMP retour
  @goToDrawP2:
    JMP DrawDeadP2
  DrawDeadP1:
    LDA timer2
    CMP #$18
    BCC @onTheGround
    JMP @falling
  @onTheGround:
    LDX #$00
    LDY #$00
    LDA #$00
    STA flip_flop
    LDA #$10
    STA row_first_tile
  @onTheGroundLoop:
    LDA posYP1
    CLC
    ADC row_first_tile
    STA SPRITE_ADDR,Y
    INY
    LDA PlayerDeathF2,X
    STA SPRITE_ADDR,Y
    INY
    LDA #$00
    STA SPRITE_ADDR,Y
    INY
    LDA flip_flop
    CMP #$01
    BEQ @row1F2
    CMP #$02
    BEQ @row2F2
    CMP #$03
    BEQ @row3F2
    CMP #$04
    BEQ @row4F2
    LDA posXP1
    STA SPRITE_ADDR,Y
    INY
    LDA #$01
    STA flip_flop
    JMP @nextOAMF2
  @row1F2:
    LDA posXP1
    CLC
    ADC #$08
    STA SPRITE_ADDR,Y
    INY
    LDA #$02
    STA flip_flop
    JMP @nextOAMF2
  @row2F2:
    LDA posXP1
    CLC
    ADC #$10
    STA SPRITE_ADDR,Y
    INY
    LDA #$03
    STA flip_flop
    JMP @nextOAMF2
  @row3F2:
    LDA posXP1
    CLC
    ADC #$18
    STA SPRITE_ADDR,Y
    INY
    LDA #$04
    STA flip_flop
    JMP @nextOAMF2
  @row4F2:
    LDA posXP1
    CLC
    ADC #$20
    STA SPRITE_ADDR,Y
    INY
    LDA row_first_tile
    CLC 
    ADC #$08
    STA row_first_tile
    LDA #$00
    STA flip_flop
  @nextOAMF2:
    INX 
    CPX #$0F
    BNE @onTheGroundLoop
    JMP retour
  @falling:
    LDX #$00
    LDY #$00
    LDA #$00
    STA flip_flop
    STA row_first_tile
  @fallingLoop:
    LDA posYP1
    CLC
    ADC row_first_tile
    STA SPRITE_ADDR,Y
    INY
    LDA PlayerDeathF1,X
    STA SPRITE_ADDR,Y
    INY
    LDA #$00
    STA SPRITE_ADDR,Y
    INY
    LDA flip_flop
    CMP #$01
    BEQ @row1
    CMP #$02
    BEQ @row2
    CMP #$03
    BEQ @row3
    LDA posXP1
    STA SPRITE_ADDR,Y
    INY
    LDA #$01
    STA flip_flop
    JMP @nextOAMF1
  @row1:
    LDA posXP1
    CLC
    ADC #$08
    STA SPRITE_ADDR,Y
    INY
    LDA #$02
    STA flip_flop
    JMP @nextOAMF1
  @row2:
    LDA posXP1
    CLC
    ADC #$10
    STA SPRITE_ADDR,Y
    INY
    LDA #$03
    STA flip_flop
    JMP @nextOAMF1
  @row3:
    LDA posXP1
    CLC
    ADC #$18
    STA SPRITE_ADDR,Y
    INY
    LDA #$00
    STA flip_flop
    LDA row_first_tile
    CLC 
    ADC #$08
    STA row_first_tile
  @nextOAMF1:
    INX 
    CPX #$0F
    BNE @fallingLoop
    JMP retour
  DrawDeadP2:
    LDA timer2
    CMP #$18
    BCC @onTheGround
    JMP @falling
  @onTheGround:
    LDX #$00
    LDY #$3C
    LDA #$00
    STA flip_flop
    LDA #$10
    STA row_first_tile
  @onTheGroundLoop:
    LDA posYP2
    CLC
    ADC row_first_tile
    STA SPRITE_ADDR,Y
    INY
    LDA PlayerDeathF2,X
    STA SPRITE_ADDR,Y
    INY
    LDA #$40
    STA SPRITE_ADDR,Y
    INY
    LDA flip_flop
    CMP #$01
    BEQ @row1F2
    CMP #$02
    BEQ @row2F2
    CMP #$03
    BEQ @row3F2
    CMP #$04
    BEQ @row4F2
    LDA posXP2
    STA SPRITE_ADDR,Y
    INY
    LDA #$01
    STA flip_flop
    JMP @nextOAMF2
  @row1F2:
    LDA posXP2
    SEC
    SBC #$08
    STA SPRITE_ADDR,Y
    INY
    LDA #$02
    STA flip_flop
    JMP @nextOAMF2
  @row2F2:
    LDA posXP2
    SEC
    SBC #$10
    STA SPRITE_ADDR,Y
    INY
    LDA #$03
    STA flip_flop
    JMP @nextOAMF2
  @row3F2:
    LDA posXP2
    SEC
    SBC #$18
    STA SPRITE_ADDR,Y
    INY
    LDA #$04
    STA flip_flop
    JMP @nextOAMF2
  @row4F2:
    LDA posXP2
    SEC
    SBC #$20
    STA SPRITE_ADDR,Y
    INY
    LDA row_first_tile
    CLC 
    ADC #$08
    STA row_first_tile
    LDA #$00
    STA flip_flop
  @nextOAMF2:
    INX 
    CPX #$0F
    BNE @onTheGroundLoop
    
    JMP retour
  @falling:
    LDX #$00
    LDY #$3C
    LDA #$00
    STA flip_flop
    STA row_first_tile
  @fallingLoop:
    LDA posYP2
    CLC
    ADC row_first_tile
    STA SPRITE_ADDR,Y
    INY
    LDA PlayerDeathF1,X
    STA SPRITE_ADDR,Y
    INY
    LDA #$40
    STA SPRITE_ADDR,Y
    INY
    LDA flip_flop
    CMP #$01
    BEQ @row1
    CMP #$02
    BEQ @row2
    CMP #$03
    BEQ @row3
    LDA posXP2
    STA SPRITE_ADDR,Y
    INY
    LDA #$01
    STA flip_flop
    JMP @nextOAMF1
  @row1:
    LDA posXP2
    SEC
    SBC #$08
    STA SPRITE_ADDR,Y
    INY
    LDA #$02
    STA flip_flop
    JMP @nextOAMF1
  @row2:
    LDA posXP2
    SEC
    SBC #$10
    STA SPRITE_ADDR,Y
    INY
    LDA #$03
    STA flip_flop
    JMP @nextOAMF1
  @row3:
    LDA posXP2
    SEC
    SBC #$18
    STA SPRITE_ADDR,Y
    INY
    LDA #$00
    STA flip_flop
    LDA row_first_tile
    CLC 
    ADC #$08
    STA row_first_tile
  @nextOAMF1:
    INX 
    CPX #$0F
    BNE @fallingLoop
  retour:
    RTS
;-------------------------------------
; end of playerDead()
;-------------------------------------

;----------------------------------- data ------------------------------------;


Cactus:
  .BYTE $2D, $2E, $2F

Arbre:
  .BYTE $3C,$3D, $4C,$4D, $5C,$5D, $6C,$6D

Background1:
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$06,$24,$0D,$2A,$05
  .BYTE $08,$06,$07,$23,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$16,$34,$1D,$2A,$15
  .BYTE $18,$16,$17,$33,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A

Background2:
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A
  .BYTE $06,$00,$0C,$04,$2A,$2A,$2A,$0E,$25,$04,$21 
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$16,$10,$1C,$14,$2A,$2A,$2A,$1E
  .BYTE $35,$14,$31,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A

InsertCoinText:
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A
  .BYTE $2A,$2A,$2A,$2A,$08,$0D,$22,$04, $21,$23,$2A,$02,$0E,$08,$0D,$2A
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A
  .BYTE $2A,$2A,$2A,$2A,$18,$1D,$32,$14, $31,$33,$2A,$12,$1E,$18,$1D,$2A
ReadyText:
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$06,$04,$23,$2A
  .BYTE $21,$04,$00,$03,$28,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$16,$14,$33,$2A
  .BYTE $31,$14,$10,$13,$38,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A

DrawText:
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$03,$21,$00
  .BYTE $26,$2A,$3A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$13,$31,$10
  .BYTE $36,$2A,$3B,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A

background:
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A  ;;row 1
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A

  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A  ;;row 2
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A

  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A  ;;row 3
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A

  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A  ;;row 4
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A

  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A  ;;row 5
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A

  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A  ;;row 6
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A

  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A  ;;row 7
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A

  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A  ;;row 8
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A

  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A  ;;row 9
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A

  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A  ;;row 10
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A

  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A  ;;row 11
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A

  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A  ;;row 12
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A

  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A  ;;row 13
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A

  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A  ;;row 14
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A

  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A  ;;row 15
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A

  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A  ;;row 16
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A

  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A  ;;row 17
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A

  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A  ;;row 18
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A

  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A  ;;row 19
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A

  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A  ;;row 20
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A

  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A  ;;row 21
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A

  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A  ;;row 22
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A

  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A  ;;row 23
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A

  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A  ;;row 24
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A

  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A  ;;row 25
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A

  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A  ;;row 26
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A

  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A  ;;row 27
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A

  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A  ;;row 28
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A

  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A  ;;row 29
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A

  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A  ;;row 30
  .BYTE $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A, $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A

attribute:
  .BYTE %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .BYTE %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .BYTE %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .BYTE %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .BYTE %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .BYTE %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .BYTE %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .BYTE %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000

paletteData:
  .BYTE $0F,$30,$30,$30,  $22,$36,$17,$0F,  $22,$30,$21,$0F,  $0F,$30,$30,$30   ;;background palette
  .BYTE $0F,$30,$30,$30,  $22,$02,$38,$3C,  $22,$1C,$15,$14,  $0F,$30,$30,$30   ;;sprite palette

Player:
  .BYTE $00,$01,$40, $02,$03,$04, $05,$06,$40, $0D,$0E,$40, $3E,$3E,$40
Player60deg:
  .BYTE $00,$01,$40, $02,$03,$11, $05,$06,$40, $0D,$0E,$40, $3E,$3E,$40
Player30deg:
  .BYTE $00,$01,$40, $02,$03,$10, $05,$06,$40, $0D,$0E,$40, $3E,$3E,$40
Player330deg:
  .BYTE $00,$01,$40, $02,$13,$40, $0A,$0B,$14, $0D,$0E,$40, $3E,$3E,$40
Player300deg:
  .BYTE $00,$01,$40, $02,$09,$40, $0A,$0B,$0C, $0D,$0E,$40, $3E,$3E,$40
PlayerAnim:
  .BYTE $0D,$0E,$40, $3E,$3E,$40, $07,$08,$40, $40,$40,$40, $3C,$3D,$40, $3E,$3E,$40, $07,$08,$40, $40,$40,$40

PlayerDeathF1:
  .BYTE $18,$19,$1A,$1B, $1C,$1D,$1E,$1F, $20,$21,$22,$40, $40,$40,$23

PlayerDeathF2:
  .BYTE $40,$40,$40,$40,$40, $24,$25,$26,$40,$40, $27,$28,$29,$2A,$2B

.SEGMENT "CHARS"
  .incbin "GunFight.chr"