# mql4-helpers

## Roadmap

2bar continuation in candles.mq4:

IMPORTANT:

* [x] Check trend with LWMA and Daily Open
* [ ] Check Round Numbers
* [ ] Check Price is at a Lower High/Higher Low.
* [ ] Check the optionals.
* [ ] Avoid spinning tops.
* [ ] Make the indicator check the bars in the current history
* [ ] Make the indicator check not only after a close, but in real time.

NICE TO HAVE:
* [ ] Improve the UI of the arrows

MODULARITY:

* [ ] Refactoring: 
  * Create new repository/ies for the separate libraries: common, drawing, candles and reuse those. Open question: how?
  * The modular libs should be reusable in all other kinds of indicators and MT4 projects. Open Source, MIT in GitHub.
