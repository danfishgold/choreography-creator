# Choreography Creator
Generate random Jazz routines.

[Check it out](https://danfishgold.github.io/choreography-creator)

Based on [Dror's version](http://www.math.tau.ac.il/~drorspei/MoveJuggler.html) but includes some extra features:

* A reverse-metronome — click it on every beat and it'll estimate the BPM of the song.
* A Start/Stop button.
* It automatically saves your last settings (moves, BPM and beat count.)

## How to Run

```
cd choreography-creator
elm make Main.elm --output elm.js
open index.html
```

Or, using [elm-live](https://github.com/tomekwi/elm-live):

```
cd choreography-creator
elm live Main.elm --output elm.js --open
```

## License

MIT
