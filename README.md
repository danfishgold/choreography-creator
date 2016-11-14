# Move Juggler
Generate random Jazz routines.

[Check it out](https://danfishgold.github.io/move-juggler)

Based on [Dror's version](http://www.math.tau.ac.il/~drorspei/MoveJuggler.html) but includes some extra features:

* A reverse-metronome — click it on every beat and it'll estimate the BPM of the song.
* A Start/Stop button.
* It automatically saves your last settings (moves, BPM and beat count.)

## How to Run

```
cd move-juggler
elm make Main.elm --output juggler.js
open index.html
```

Or, using [elm-live](https://github.com/tomekwi/elm-live):

```
cd move-juggler
elm live Main.elm --output juggler.js --open
```

## License

MIT
