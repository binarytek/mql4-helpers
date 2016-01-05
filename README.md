# mql4-helpers

## Roadmap

2bar continuation in candles.mq4:

IMPORTANT:

* [x] Check trend with LWMA and Daily Open.
* [ ] Expose extern indicator variables.
* [ ] Check Round Numbers.
* [ ] Check Price is at a Lower High/Higher Low.
* [ ] Check the optionals.
* [ ] Avoid spinning tops.
* [x] Run the bars in the current history. BUT [the Daily Open may not be accurate for every day](http://www.binaryoptionsedge.com/topic/2095-different-daily-open-on-m5-and-d1/).
* [ ] Check not only after a close, but in real time.

NICE TO HAVE:
* [ ] Improve the UI of the arrows

MODULARITY:

* [ ] Refactoring: 
  * Create new repository/ies for the separate libraries: common, drawing, candles and reuse those. Open question: how?
  * The modular libs should be reusable in all other kinds of indicators and MT4 projects. Open Source, MIT in GitHub.
