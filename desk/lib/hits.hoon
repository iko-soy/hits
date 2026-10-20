/-  *hits
|%
::  +insert: put .new into .times, which is kept newest first
::
::    +sort is a quicksort, which is quadratic on a sorted list
::
++  insert
  |=  [new=time times=(list time)]
  ^-  (list time)
  =|  newer=(list time)
  |-
  ?:  |(?=(~ times) (gte new i.times))
    (weld (flop newer) [new times])
  $(newer [i.times newer], times t.times)
::
::  install times
::
::    a hit's .time tells installs apart. older versions sent now.bowl,
::    or a desk's first revision time, to which vere gives 16 fractional
::    bits: the lower 48 bits are zero. ours aren't: a new install's
::    time has its lowest bit set, see +fresh, and an install from
::    before this version has its lowest bit clear, see +moved
::
++  stamp
  |=  =time
  ^-  ?(%old %new %moved)
  ?:  =(0 (end [0 48] time))  %old
  ?:  =(1 (end 0 time))  %new
  %moved
::
::  +fresh: the time we tell of a new install with
::
::    with random bits, since every ship scans at the same moments
::
++  fresh
  |=  [now=@da eny=@uvJ]
  ^-  time
  (con 1 (mix (claim now) (end [0 48] eny)))
::
::  +moved: the time we tell of an install from before this version
::
::    older versions told of it with .old, its desk's first revision
::    time. that's the publisher's commit time, the same on each ship
::    that installed the same revision, so we mix in a hash of our
::    name. a peer that counted .old swaps it for this, see +claim,
::    unless it's still on an older version: then it counts this too
::
++  moved
  |=  [our=ship old=time]
  ^-  time
  (add (claim old) (lsh 0 (max 1 (end [0 47] (sham our)))))
::
::  +claim: the time older versions told of a moved install with
::
++  claim
  |=  =time
  ^-  @da
  (lsh [0 48] (rsh [0 48] time))
::
++  scry-kelvin
  |=  [our=@p =desk now=@da]
  ^-  @ud
  ::  XX assumes we only care about %zuse compat for now
  ::     should get this squared away before release
  ::
  ::  XX starting to think this is not quite right: instead
  ::     of storing the lowest kelvin and returning that
  ::     on scry, we should return the whole list of %zuse
  ::     versions which the dev has explicitly declared
  ::     the app to be compatible with
  ::
  ::  return lowest kelvin number
  ::  in the app's sys.kelvin
  (need (read-kelvin our desk now))
::
::  +read-kelvin: lowest %zuse kelvin in a local desk's sys.kelvin
::
::    ~ if the desk has no sys.kelvin, or no %zuse in it
::
++  read-kelvin
  |=  [our=@p =desk now=@da]
  ^-  (unit @ud)
  =/  =path  /(scot %p our)/[desk]/(scot %da now)/sys/kelvin
  ?.  .^(? %cu path)
    ~
  =/  kelvins=(list @ud)
    %+  sort
      %+  murn
        ~(tap in (waft-to-wefts:clay .^(waft:clay %cx path)))
      |=  [vane=@tas kelvin=@ud]
      ^-  (unit @ud)
      ?.  =(vane %zuse)  ~
      `kelvin
    lth
  ?~  kelvins
    ~
  `i.kelvins
::
::  +local-desk: the desk we installed .app on, according to kiln
::
::    |install ~pub %foo, =local %bar installs ~pub's %foo as our %bar.
::    ~ if we haven't installed it
::
++  local-desk
  |=  [our=@p now=@da =app]
  ^-  (unit desk)
  =/  sources
    .^((map desk [ship desk]) %gx /(scot %p our)/hood/(scot %da now)/kiln/sources/noun)
  =/  found=(list desk)
    %+  murn  ~(tap by sources)
    |=  [=desk source=[ship desk]]
    ?.(=(source app) ~ `desk)
  ?~  found
    ~
  `i.found
::
++  skip-desk
  |=  =desk
  ^-  ?
  ?|  =(desk %base)
      =(desk %hits)
      =(desk %kids)
      =(desk %talk)
      =(desk %garden)
      =(desk %landscape)
  ==
::
::  +hidden: apps we count and gossip about, but don't show
::
++  hidden
  |=  =app
  ^-  ?
  ?=(?(%neo %groups %webterm) desk.app)
::
::  +good-app: an app we can count, and ask its publisher about
::
::    no comets, and no ships wider than a moon: clan:title, and jael
::    and ames when we read the docket, crash on ships wider than 128
::    bits. the desk must be a term, since clay parses it back out of
::    the wire of its remote read, and short, since we show it
::
++  good-app
  |=  =app
  ^-  ?
  ?&  (lte (met 3 ship.app) 8)
      (lte (met 3 desk.app) 64)
      ?=(^ (slaw %tas desk.app))
  ==
::
::  sizes we can show
::
::    eyre renders our facts to JSON without virtualizing, see
::    mar/ui-update: +time:enjs crashes on a time before 1970, and
::    numbers take time quadratic in their size to render. so we keep
::    no hit or docket with atoms bigger than they ever need to be,
::    nor a docket with a longer path than a site needs.
::    a hit can't be from the future either, but clocks drift
::
++  sane-time
  |=  [now=@da =time]
  ^-  ?
  &((gte time ~1970.1.1) (lte time (add now ~d1)))
::
++  sane-kelvin
  |=  =kelvin
  ^-  ?
  (lte (met 3 kelvin) 2)
::
++  sane-docket
  |=  =docket-0
  ^-  ?
  =/  =href  href.docket-0
  ?&  (lte (met 3 color.docket-0) 3)
      (lte (met 5 major.version.docket-0) 1)
      (lte (met 5 minor.version.docket-0) 1)
      (lte (met 5 patch.version.docket-0) 1)
      ?-  -.href
      ::
          %site
        ::  before the +jam below, which is slow on some long lists
        ::
        ?&  (lte (lent path.href) 32)
            (levy path.href |=(=knot (lte (met 3 knot) 256)))
        ==
      ::
          %glob
        ?&  (lte (met 3 hash.glob-reference.href) 16)
            ?|  ?=(%http -.location.glob-reference.href)
                (lte (met 3 ship.location.glob-reference.href) 16)
        ==  ==
      ==
      ::  text is quick to render, except the website, see
      ::  mar/ui-update. but each frontend load gets every docket.
      ::  a mebibyte fits an icon inlined as a data: url
      ::
      (lte (met 3 (jam docket-0)) 1.048.576)
  ==
::
::  $chat-crew: the parts of a %chat club's crew that we read
::
::    we joined a club if we're in .team, invitees are in .hive.
::    (.net doesn't tell: it's %done for clubs we're invited to too)
::
+$  chat-crew
  $:  team=(set ship)
      hive=(set ship)
      *
  ==
::
++  max-club   10  ::  members in the biggest group dm we take peers from
++  max-peers  50  ::  ships we gossip with because we chat with them
::
::  +chat-peers: ships we chat with in tlon's %chat, see +pick-peers
::
::    ~ if %chat isn't running, or its dms or blocks don't parse.
::    clubs that don't parse count as none.
::    a scry %chat can't answer still crashes, and +mule can't catch
::    that inside an agent, so call this from an event of its own
::
++  chat-peers
  |=  [our=ship now=@da]
  ^-  (unit (set ship))
  =/  base=path  /(scot %p our)/chat/(scot %da now)
  ?.  .^(? %gu (snoc base %$))
    ~
  ::  ask for /noun, so we don't depend on %chat's mark names
  ::
  =/  ships
    |=  =path
    ((soft (set ship)) .^(* %gx (weld base (snoc path %noun))))
  =/  dms  (ships /dm)
  =/  blocked  (ships /blocked)
  =/  blocked-by  (ships /blocked-by)
  ?.  &(?=(^ dms) ?=(^ blocked) ?=(^ blocked-by))
    ((slog leaf+"hits: unexpected dms or blocks from %chat" ~) ~)
  =/  clubs=(map @ chat-crew)
    =/  clubs
      ((soft (map @ chat-crew)) .^(* %gx (weld base /clubs/noun)))
    ?^  clubs  u.clubs
    ((slog leaf+"hits: unexpected group dms from %chat" ~) ~)
  `(pick-peers our u.dms (~(uni in u.blocked) u.blocked-by) clubs)
::
::  +pick-peers: who to gossip with, of the ships we chat with
::
::    partners in dms we started or accepted, then members of group
::    dms (clubs) we joined that have at most +max-club members, minus
::    ourselves, blocked ships and atoms too wide to be ships, in
::    @p order: at most +max-peers of them, dms first.
::    anyone can poke %chat to make a club with us in its team, so the
::    caps bound how many ships a stranger can make us talk to
::
++  pick-peers
  |=  $:  our=ship
          dms=(set ship)
          blocked=(set ship)
          clubs=(map @ chat-crew)
      ==
  ^-  (set ship)
  =/  members=(set ship)
    %-  ~(rep by clubs)
    |=  [[* crew=chat-crew] members=(set ship)]
    ?.  (~(has in team.crew) our)
      members
    ?:  (gth ~(wyt in team.crew) max-club)
      members
    (~(uni in members) team.crew)
  =/  pick
    |=  who=(set ship)
    ^-  (list ship)
    %+  skip  (sort ~(tap in who) lth)
    |=  =ship
    ?|  =(our ship)
        (~(has in blocked) ship)
        (gth (met 3 ship) 16)
    ==
  %-  silt
  %+  scag  max-peers
  (weld (pick dms) (pick (~(dif in members) dms)))
--
