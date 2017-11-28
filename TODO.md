This document contains my thoughts on where I'd like to take this script in the future, mostly in no particular order.

## Certain to happen

* filtering — JS needs to be able to parse / reorder tattoo blocks
* random tattoo — Should be trivial in JS.
* add missing tattoos — TheKolWiki has more sigils than show up in [a search for `otherimages/sigils`](http://kol.coldfront.net/thekolwiki/index.php?title=Special:Search&limit=500&offset=0&ns6=1&search=otherimages%2Fsigils), in spite of containing that text (such as [`baketat`](http://kol.coldfront.net/thekolwiki/index.php/File:Baketat.gif).  I don't want to crawl the wiki, but I need as much data as I can get, so I need to figure something out.

## Might happen

* other sort orders — Restore to by-sigil sort?  Is there any value to other sorts?
* custom section ordering — Would need stored in preferences, presumably using ZLib.
* remembering section collapse state — Ditto preferences.
* hiding individual tattoos — Sounds cool, but might be a hassle.  Work on other stuff first.
* choose between 2-/3-column layout — Again, needs stored somewhere.

## Won't happen

* unearned tattoo tracking — Use [Cheesecookie's Snapshot Maker](http://forums.kingdomofloathing.com/vb/showthread.php?t=218735) instead.