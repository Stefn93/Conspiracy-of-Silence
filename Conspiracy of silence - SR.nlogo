;;Stefano Romanazzi
;;stefan.romanazzi@gmail.com
;;student ID: 819445

globals[defections turtlecount turtleno punishcount metapunishcount sd mn difft d maxappr minappr defappr kills risktot risk lawfulkilled]
turtles-own[points boldness vengefulness learning seen? punish? danger courage appreciation]

to setup
  clear-all
  set turtlecount 100
  set defections 0
  addturtles turtlecount 0 0 0 1 1 0
  reset-ticks
end

to go1000
  repeat 1000[
   go
  ]
end

to go

  ask turtles[
    ;;initialization of temporary variables
      set punishcount 0
      set metapunishcount 0
      set lawfulkilled 0
      set d 0


      ;; Chance of being seen
      set seen? random-float 1

      ;; Defect if think you can get away with it
      if seen? < boldness
         [  ;; Choose to defect
           set points points + 3
           set defections defections + 1
           set d danger  ;;store danger of the defector
           set defappr 0

          ask other turtles [
            ;; hurt caused by defection
            set points points - 1

            ;; Did they see this?
            if random-float 1 < seen?[
              ;; Yes, they saw it

              ;; Chance of avoiding punishment
              set punish? random-float 1

              ;; Are they going to punish?
              ifelse vengefulness * courage > punish? * d [
                ;; they chose to punish
                set punishcount punishcount + 1
                set appreciation appreciation + 5
                set points points - 2
                set defappr 1

                if Conspiracy[
                  ifelse (d > 0.8) and (random-float 1 < d) [
                     ;;the criminal is dangerous enough to kill
                     set kills kills + 1
                     set risktot risktot + 1
                     if (appreciation > mean[appreciation] of turtles )[
                       set lawfulkilled lawfulkilled + 1
                     ]

                     die
                  ][
                     set risktot risktot + 1
                  ]
                ]
              ]
              [
                ;; They did not punish; Enforce metanorm version
                if Metanorm[
                  ;; change rules

                  ask other turtles[
                    ;; enforce metanorm
                    if random-float 1 < seen?[
                       set metapunishcount metapunishcount + 1
                       set appreciation appreciation + 3
                       set points points - 2

                    ]
                  ]

                  if Learn [
                    if points < mean [points] of turtles[
                      ;; The criminal has way less points than the average, so he seeks revenge and gets more dangerous

                      set vengefulness vengefulness * 1.4 + learning
                      if vengefulness > 1[ set vengefulness 1 ]
                    ]
                  ]

                  set points points - (9 * metapunishcount)
                  set appreciation appreciation - (3 * metapunishcount)
                  set metapunishcount 0
                ]
                ;;They did not punish
              ]
            ]
            ;;calculate the appreciation in function of courage and danger
            if Conspiracy[
              set appreciation appreciation + (precision courage 3) - (precision danger 3)
            ]
          ]

          ;; Appreciation falls
          if defappr = 1[
            set appreciation appreciation - (9 * punishcount)
          ]

          ;; Apply punishment to defector
          set points points - (9 * punishcount)

          ;; The Criminal tries to Learn from his errors
          if Learn [
            ifelse points < mean [points] of turtles [
              ;; The criminal has less points than the average, so he seeks revenge and gets more dangerous

              set vengefulness vengefulness * 1.4 + learning
              if vengefulness > 1[ set vengefulness 1 ]

              if Conspiracy [
                set danger danger * 1.2 + learning
                if danger > 1 [ set danger 1]
              ]
            ][
              ;; The criminal has more points than the average, so he commits less crimes and gets braver

              set boldness boldness * 0.8 - learning
              if boldness < 0[ set boldness 0 ]

              if Conspiracy [
                set courage courage * 1.2 + learning
                if courage > 1 [ set courage 1 ]
              ]
            ]
          ]

          ;;reset variables
          set punishcount 0
          set defappr 0
         ]
  ]

  set maxappr max[appreciation] of turtles
  set minappr min[appreciation] of turtles
  if Conspiracy and risktot > 0[
    ;;calculate the chance that each agent gets killed by a dangerous criminal after punishing him
    set risk kills / risktot
  ]
  set lawfulkilled ((lawfulkilled) / (count turtles))  ;;calculate the risk of being killed in relation with an high appreciation

  ;; evolution. Turtles replicate more if successful in strategies
  set sd standard-deviation [points] of turtles
  set mn mean [points] of turtles

  if natural-selection[
    ;; Allow society to get better through natural-selection of most promising individuals

    ask turtles[
      ;;show points

      if points >= mn + sd[
        ;; Most successful individuals have 3 offspring
        hatch 3 [
          set points 0
          setxy random 30 random 30
          set color green  ;;mark most successful individuals with green color
        ]
      ]
      if (points >= mn - sd) and (points < mn + sd) [
        ;; Mean individuals have just one offspring
        hatch 1 [
          set points 0
          setxy random 30 random 30
          set color blue  ;;mean individuals will be blue
        ]
      ]
      die
    ]
  ]


  set difft  turtlecount - count turtles
  ;;kill the exceeding population

  ifelse difft < 0[
    repeat difft * -1[
      ask turtle min[who] of turtles [
       die
      ]
    ]
  ][
     addturtles difft 0 0 0 1 1 0
  ]

  if Mutations[
    ;; mutation of features

    ask turtles [

      if random-float 1 <= 0.01[
        set boldness random-float 1
      ]

      if random-float 1 <= 0.01[
        set vengefulness random-float 1
      ]

      if Conspiracy[
        if random-float 1 <= 0.01[
          set danger random-float 1
        ]
        if random-float 1 <= 0.01[
          set courage random-float 1
        ]
      ]

      if Learn[
        if random-float 1 <= 0.01[
          set learning random-float 1
        ]
      ]

    ]
  ]

  ;;update-plots
  tick
  set defections 0
end


to addturtles [num bold venge pts cour dan lear]
  create-turtles num[

    ;;default initialization

    ifelse bold = 0[
      set boldness random-float 1
    ][
     set boldness bold
    ]

    ifelse venge = 0[
      set vengefulness random-float 1
    ][
      set vengefulness venge
    ]

    ifelse cour = 1[
      ifelse Conspiracy[
         set courage random-float 1
      ][
         set courage cour
      ]
    ][
      set courage cour
    ]

    ifelse dan = 1[
      ifelse Conspiracy[
         set danger random-float 1
      ][
         set danger dan
      ]
    ][
      set danger dan
    ]

    ;;defines the learning rate of the turtle (how quickly the agent learns from his errors)
    ifelse lear = 0[
      ifelse Learn[
         set learning random-float 1
      ][
         set learning lear
      ]
    ][
      set learning lear
    ]

    set appreciation 0
    set points pts
    setxy random 30 random 30  ;; individuals are randomly placed in the grid, the location of the turtle doesn't affect anything
    set shape "person"
    set size 0.8
    set color red  ;;color of newly born individuals
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
182
11
633
483
16
16
13.364
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
3
11
178
59
Start
setup
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
3
68
82
101
Loop
Go
T
1
T
OBSERVER
NIL
G
NIL
NIL
1

PLOT
839
164
1038
314
Population Characteristics
vengefulness
boldness
0.0
1.0
0.0
1.0
true
false
"" ""
PENS
"pen-0" 1.0 0 -15390905 true "" "plotxy mean [vengefulness] of turtles mean [boldness] of turtles"

PLOT
637
317
1038
485
Defections
ticks
defections
0.0
100.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -5298144 true "" "plotxy ticks defections"

BUTTON
91
68
177
101
loop 1000
go1000
NIL
1
T
OBSERVER
NIL
L
NIL
NIL
1

PLOT
635
11
835
161
Mean Boldness of agents
ticks
boldness
0.0
1.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -15390905 true "" "plotxy ticks mean [boldness] of turtles"

PLOT
636
164
836
314
Mean Vengefulness of agents
ticks
vengefulness
0.0
1.0
0.0
1.0
true
false
"" ""
PENS
"default" 0.1 0 -15390905 true "" "plotxy ticks mean [vengefulness] of turtles"

SWITCH
3
108
177
141
Metanorm
Metanorm
0
1
-1000

PLOT
1043
164
1243
314
Mean Danger of agents
ticks
danger
0.0
1.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -13345367 true "" "plotxy ticks mean [danger] of turtles"

PLOT
1045
316
1245
484
Mean Courage of agents
ticks
courage
0.0
1.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -13345367 true "" "plotxy ticks mean [courage] of turtles"

PLOT
1043
11
1242
161
Conspiracy of silence
danger
courage
0.0
1.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -13345367 true "" "plotxy mean [danger] of turtles mean [courage] of turtles"

PLOT
839
11
1039
161
Mean Points
NIL
NIL
0.0
100.0
-2000.0
2000.0
true
false
"" ""
PENS
"default" 1.0 0 -15390905 true "" "plot mn"

SWITCH
4
146
177
179
Conspiracy
Conspiracy
0
1
-1000

PLOT
1247
11
1481
161
Appreciation
ticks
appreciation
0.0
250.0
0.0
30.0
true
false
"" ""
PENS
"default" 1.0 0 -13345367 true "" "plotxy ticks mean[appreciation] of turtles"

MONITOR
1249
164
1363
209
Max appreciation
maxappr
0
1
11

MONITOR
1372
164
1482
209
Min appreciation
minappr
0
1
11

PLOT
1250
211
1483
361
Risk of being killed by criminals
ticks
chance
0.0
100.0
0.0
0.1
true
false
"" ""
PENS
"default" 1.0 0 -13345367 true "" "plot risk"

PLOT
1250
364
1483
484
Killed agents with mid-high appreciation
ticks
deaths
0.0
100.0
0.0
0.1
true
false
"" ""
PENS
"default" 1.0 0 -13345367 true "" "plotxy ticks lawfulkilled"

SWITCH
5
183
177
216
Learn
Learn
0
1
-1000

SWITCH
5
221
177
254
Natural-selection
Natural-selection
0
1
-1000

SWITCH
6
258
177
291
Mutations
Mutations
0
1
-1000

@#$#@#$#@
## WHAT IS IT?

Model constructed based on Axelrod (1986) An Evolutionary Approach to Norms. Axelrod's proposed norms game provides a game-theoretic/evolutionary simulation of how norms might evolve in a community based on negative feedback through punishment. A conspiracy of silence extension has been added to the model: it allows to experiment the effects of omertà in a defecting society. The omertà can be fought through the learning mechanism and the natural selection.

## HOW IT WORKS

100 agents are created with random boldness, vengefulness, courage and danger between 0 and 1. With each run, an agent has an opportunity to "defect" based on their boldness and a random likeliness of being caught. If the conspiracy of silence is enabled, also the courage of the potential punisher and the danger of the defector can influence this decision. A defection carries a positive score of 3 and a loss of 1 to all other agents.

If other agents observe the defection they choose to punish it with a likelihood based on their vengefulness level. Punishment is -9 to the defecting agent, with a -2 cost to the punishing agent.

In the "metanorms" condition, agents are also punished if they chose not to punish an observed defector.

After each round, the agents with the best scores reproduce thrice, the agents with mean score reproduce just once.
A mutation factor can also modify turtles' features with a 1% chance.

## HOW TO USE IT

- Start (S) to reset the model.
- loop (G) for a continuous execution.
- loop1000 (L) to run a full simulation.

5 switches allow to modify the activation of the various extensions:

- Metanorms: enhances Axelrod's metanorms. Each agent caught turning a blind eye after observing a defection, can be punished in turn.
- Conspiracy of silence: enables the effects of omertà in the society. Agents with low courage avoid punishing fearful criminals (with high danger), thus reducing punishments.
- Learn: enables the learning mechanism that makes weaker defectors more vengeful and powerful defectors less bold. Both behaviours help the society to get better.
- Natural selection: enables the reproduction of the most successful individuals in the society.
- Mutations: enables random mutations of individuals with a 1% chance.

## THINGS TO NOTICE

In the metanorms condition, convergence on a stable state of high vengefulness is more rapid and predictable - as enacting a punishment is reinforced.

## THINGS TO TRY

Try enabling the different mechanisms in this order, hence noticing the changes among the executions:

- Mutation
- Natural selection
- Conspiracy of silence
- Learn
- Metanorms

Does each component generate the expected results in the society?

## CREDITS AND REFERENCES
v1.0 Stefano Romanazzi, 2017.
University of Bologna.

e-mail: 	stefan.romanazzi@gmail.com
student ID: 	819445

AXELROD, R., 1986. An Evolutionary Approach to Norms.
The American Political Science Review.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.3.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
