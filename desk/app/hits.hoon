/-  *hits
/+  *hits, gossip, default-agent
::  XX get marks in a /mar/hits folder and improve the
::     names; something like %hits-install and %hits-refresh
/$  grab-hit            %noun  %hit
/$  grab-update-docket  %noun  %update-docket
::
|%
+$  state-versions
  $%  state-0
      state-1
  ==
::
+$  state-0
  $:  %0
      local=(set app)
      rankings=(list app)
      scores=(map app score)
      versions=(map app kelvin)
      installs=(map app (list time))
      dockets=(map app docket-0)
  ==
::
+$  state-1
  $:  %1
      local=(map app ours)            ::  our locally-installed apps
      rankings=(list app)             ::  unused, the frontend ranks apps
      scores=(map app score)          ::  app scores
      versions=(map app kelvin)       ::  app versions
      installs=(map app (list time))  ::  most recent installs
      dockets=(map app docket-0)      ::  docket info for each app
  ==
::
::  ours: what we tell peers about an app we've installed
::
::    .time is set when we first see the app installed, and stays the
::    same until it's uninstalled. every scan refreshes .kelvin
::
+$  ours  [=time =kelvin]
::
::  hit: message sent between ships on each app (un)install
::
::    .time tells installs apart: we send the same .time in every hit
::    about one install (live, whenever a peer subscribes, and when it's
::    uninstalled), so that peers count each install once.
::    older versions sent now.bowl live, but the desk's first revision
::    time on subscription, so their installs may still count twice.
::    see +stamp for how we tell their times from ours
::
+$  hit
  $:  =time       ::  which install this is about
      =app        ::  app's publisher and name
      =kelvin     ::  app's kelvin compatibility
      =installed  ::  installed or uninstalled?
  ==
::
+$  card  $+(card card:agent:gall)
::
::  +tell-ui: give the frontend an update
::
++  tell-ui
  |=  upd=ui-update
  ^-  card
  [%give %fact ~[/ui-updates] %ui-update !>(upd)]
::
::  +read-docket: ask the app's publisher for its docket
::
++  read-docket
  |=  [now=@da =app]
  ^-  card
  :*  %pass
      /docket/read/(scot %p ship.app)/(scot %tas desk.app)
      %arvo
      %k
      %fard
      %base
      %read
      %noun
      !>  ^-  [~ care:clay ship desk case path]
      [~ %q ship.app desk.app [%da now] /desk/docket-0]
  ==
::
::  +docket-wire: where we hear of changes to .app's docket
::
++  docket-wire
  |=  =app
  ^-  wire
  /docket/update/(scot %p ship.app)/(scot %tas desk.app)
::
::  +watch-docket: hear of the next change to a local desk's docket
::
++  watch-docket
  |=  [=wire our=ship =desk now=@da]
  ^-  card
  [%pass wire %arvo %c %warp our desk ~ %next %x [%da now] /desk/docket-0]
::
::  +listed: whether the frontend may list .app
::
::    not if we hide it, or if it was only ever seen with a kelvin
::    older than our %base's
::
++  listed
  |=  [base=kelvin =app =kelvin]
  ^-  ?
  &(!(hidden app) (lte kelvin base))
::
::  +learn: count a hit we sent or heard, once per install
::
::    a hit about an install we've already counted can only bring news
::    of its kelvin, or of the time we count it with, see +moved.
::    hits from older versions don't tell which install was removed, so
::    for those we drop the most recent install they could have told of
::    instead.
::    we count hidden apps too, but tell the frontend nothing of them
::
++  learn
  |=  [=bowl:gall state=state-1 =hit]
  ^-  (quip card state-1)
  =*  now  now.bowl
  ?.  ?&  (good-app app.hit)
          (sane-time now time.hit)
          (sane-kelvin kelvin.hit)
      ==
    [~ state]
  =;  [cards=(list card) learnt=state-1]
    [?:((hidden app.hit) ~ cards) learnt]
  =/  known=(list time)  (~(gut by installs.state) app.hit ~)
  =/  has  |=(new=time (lien known |=(t=time =(t new))))
  ::  the time we count this install with, if we count it
  ::
  =/  counted=(unit time)
    ?:  (has time.hit)
      `time.hit
    ?.  &(=(%moved (stamp time.hit)) (has (claim time.hit)))
      ~
    `(claim time.hit)
  ::  the time of our own install, see +ours
  ::
  =/  mine=(unit time)
    (bind (~(get by local.state) app.hit) |=(ours time))
  ?:  installed.hit
    =/  old=(unit kelvin)  (~(get by versions.state) app.hit)
    =/  new=kelvin  ?~(old kelvin.hit (min u.old kelvin.hit))
    =.  versions.state  (~(put by versions.state) app.hit new)
    ?^  counted
      ::  count it with its own time from now on, so that another
      ::  install with the same older time can count too
      ::
      =?  installs.state  !=(u.counted time.hit)
        %+  ~(put by installs.state)  app.hit
        (insert time.hit (skip known |=(t=time =(t u.counted))))
      :_  state
      ?:  =(`new old)  ~
      ::  the frontend may only list it now, see +listed. we read the
      ::  docket again, but give what we have in case nobody answers
      ::
      =/  base=(unit kelvin)  (read-kelvin our.bowl %base now)
      =/  stored=(unit docket-0)  (~(get by dockets.state) app.hit)
      :*  (tell-ui %version-update app.hit new)
          (read-docket now app.hit)
          ?.  &(?=(^ base) ?=(^ stored) (listed u.base app.hit new))
            ~
          :_  ~
          %-  tell-ui
          :*  %app-update
              app.hit
              (lent known)
              new
              (~(got by installs.state) app.hit)
              u.stored
          ==
      ==
    =/  times=(list time)  (insert time.hit known)
    =.  scores.state    (~(put by scores.state) app.hit (lent times))
    =.  installs.state  (~(put by installs.state) app.hit times)
    ::
    ::  ask for docket info from the app's publisher
    ::
    :_  state
    :~  (tell-ui %score-update app.hit (lent times))
        (tell-ui %installs-update app.hit times)
        (read-docket now app.hit)
    ==
  =;  times=(list time)
    ?:  =(times known)
      [~ state]
    ?~  times
      ::  that was the last install we knew of, forget the app
      ::
      =.  scores.state    (~(del by scores.state) app.hit)
      =.  versions.state  (~(del by versions.state) app.hit)
      =.  installs.state  (~(del by installs.state) app.hit)
      =.  dockets.state   (~(del by dockets.state) app.hit)
      :_  state
      :~  (tell-ui %score-update app.hit 0)
          (tell-ui %installs-update app.hit ~)
      ==
    =.  scores.state    (~(put by scores.state) app.hit (lent times))
    =.  installs.state  (~(put by installs.state) app.hit times)
    :_  state
    :~  (tell-ui %score-update app.hit (lent times))
        (tell-ui %installs-update app.hit times)
    ==
  ::  our own install stays while we have it: /scan learns our
  ::  uninstall once it's gone from .local
  ::
  ?:  &(?=(^ counted) =(counted mine))
    known
  ?^  counted
    (skip known |=(t=time =(t u.counted)))
  ::  an install we never counted. older versions don't tell which
  ::  install was removed, so for theirs we drop the most recent one
  ::  they could have told of: an %old time, which ours never are.
  ::  so too for a moved install, which we may have counted with the
  ::  time an older version told of it with live, see +moved
  ::
  ?:  =(%new (stamp time.hit))
    known
  =/  older=(list time)  (skim known |=(t=time =(%old (stamp t))))
  ?~  older
    known
  (skip known |=(t=time =(t i.older)))
::
::  +learn-all: +learn each of .hits, in order
::
++  learn-all
  |=  [=bowl:gall state=state-1 hits=(list hit)]
  ^-  (quip card state-1)
  =|  cards=(list card)
  |-  ^-  (quip card state-1)
  ?~  hits
    [cards state]
  =^  caz  state  (learn bowl state i.hits)
  $(hits t.hits, cards (weld cards caz))
::
::  +state-0-to-1: upgrade, without counting anything again
::
::    our initial dump used to tell of each of our installs with the
::    first revision time of the desk named after the app, and peers
::    have counted those, so we tell of them with +moved times.
::    repeats of a time were counted by mistake (from dumps with a new
::    kelvin), and so were older times next to their moved ones (from
::    upgraded peers' dumps), so we drop those. we drop what +learn now
::    ignores, and dockets we can't show, too.
::    and we count our own installs, which we only heard back by chance
::
++  state-0-to-1
  |=  [=bowl:gall old=state-0]
  ^-  (quip card state-1)
  =/  installs=(map app (list time))
    %-  ~(rep by installs.old)
    |=  [[=app times=(list time)] installs=(map app (list time))]
    ::  its kelvin is the lowest of all its hits
    ::
    ?.  ?&  (good-app app)
            (sane-kelvin (~(gut by versions.old) app 0))
        ==
      installs
    =/  have=(set time)
      (silt (skim times |=(=time (sane-time now.bowl time))))
    =/  claimed=(set time)
      %-  silt
      %+  murn  ~(tap in have)
      |=  =time
      ?.  =(%moved (stamp time))  ~
      `(claim time)
    =.  times  ~(tap in (~(dif in have) claimed))
    ?~  times  installs
    (~(put by installs) app (sort times gth))
  =/  scores=(map app score)  (~(run by installs) lent)
  =/  tracked  |=([=app *] (~(has by installs) app))
  =/  desks=rock:tire:clay
    .^(rock:tire:clay %cx /(scot %p our.bowl)//(scot %da now.bowl)/tire)
  =/  local=(map app ours)
    %-  ~(rep in local.old)
    |=  [=app local=(map app ours)]
    ?~  dump=(dumped bowl desks app)  local
    (~(put by local) app u.dump)
  %^  learn-all  bowl
    :*  %1
        local
        ~
        scores
        (malt (skim ~(tap by versions.old) tracked))
        installs
        %-  malt
        %+  skim  ~(tap by dockets.old)
        |=([=app =docket-0] &((tracked app ~) (sane-docket docket-0)))
    ==
  %+  turn  ~(tap by local)
  |=([=app ours] `hit`[time app kelvin &])
::
::  +dumped: what we tell of .app, which older versions told of in
::  their initial dump
::
::    ~ if they couldn't have told of it
::
++  dumped
  |=  [=bowl:gall desks=rock:tire:clay =app]
  ^-  (unit ours)
  ?.  (~(has by desks) desk.app)
    ~
  =/  last=cass:clay
    .^(cass:clay %cw /(scot %p our.bowl)/[desk.app]/(scot %da now.bowl)/noun)
  ?:  =(0 ud.last)
    ~
  =/  kelvin  (read-kelvin our.bowl desk.app now.bowl)
  ?~  kelvin
    ~
  =/  first=cass:clay
    .^(cass:clay %cw /(scot %p our.bowl)/[desk.app]/1/noun)
  `[(moved our.bowl da.first) u.kelvin]
::
::  +arm-timers: (re)arm the five-minute loop on the next boundary
::
::    %rest first, so that arming from both +on-load and the
::    loop's own %wake leaves one timer, not two loops
::
++  arm-timers
  |=  now=@da
  ^-  (list card)
  =/  next=@da  (add (sub now (mod now ~m5)) ~m5)
  :~  [%pass /timers %arvo %b %rest next]
      [%pass /timers %arvo %b %wait next]
  ==
--
::
=|  state-1
=*  state  -
::
::  /lib/gossip.hoon config
%-  %+  agent:gossip
      [2 %targets %anybody |]
    %-  %~  put  by
      %-  %~  put  by
        *(map mark $-(* vase))
      [%hit |=(n=* !>((grab-hit n)))]
    [%update-docket |=(n=* !>((grab-update-docket n)))]
::
^-  agent:gall
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %|) bowl)
::
++  on-init
  ::
  ::  immediately populate our local state and gossip around
  ^-  (quip card _this)
  :_  this
  :~  :*  %pass
          /timers
          %arvo
          %b
          %wait
          now.bowl
      ==
  ==
::
++  on-save
  !>(state)
::
++  on-load
|=  =vase
  ^-  (quip card _this)
  =/  saved-state
    !<(state-versions vase)
  =^  cards  state
    ?-  -.saved-state
      %0  (state-0-to-1 bowl saved-state)
      ::  earlier builds of this version kept .rankings
      ::
      %1  [~ saved-state(rankings ~)]
    ==
  ::
  ::  have an open frontend subscribe again, since what it may list
  ::  depends on our %base's kelvin, which an upgrade may change.
  ::  re-arm the loop, in case gall dropped a %wake while we were
  ::  suspended, and update who we chat with in an event of its own
  ::
  :_  this
  :+  [%give %kick ~[/ui-updates] ~]
    [%pass /peers %arvo %b %wait now.bowl]
  (weld (arm-timers now.bowl) cards)
::
++  on-poke  on-poke:def
++  on-watch
  |=  =path
  ^-  (quip card _this)
  ?+  path
    (on-watch:def path)
  ::
      [%ui-updates ~]
    ::
    ::  frontend listens to our ship for new hits;
    ::  will update the chart live on the user device
    ?>  =(our.bowl src.bowl)
    =/  base-version
      (scry-kelvin our.bowl %base now.bowl)
    :_  this
    %+  murn
      ~(tap by scores)
    |=  [=app *]
    ^-  (unit card)
    =/  app-score     (~(get by scores) app)
    =/  app-version   (~(get by versions) app)
    =/  app-installs  (~(get by installs) app)
    ::
    ::  skip an app we're missing anything for, rather than crash
    ::
    ?:  ?|  ?=(~ app-score)
            ?=(~ app-version)
            ?=(~ app-installs)
            !(listed base-version app u.app-version)
        ==
      ~
    :-  ~
    :*  %give
        %fact
        ~
        %ui-update
        !>  ^-  ui-update
        :*  %app-update
            app
            u.app-score
            u.app-version
            u.app-installs
            (~(gut by dockets) app *docket-0)
        ==
    ==
  ::
      [%~.~ %gossip %source ~]
    ::
    ::  neighbours listen for new hits from us. we tell of each
    ::  install exactly as we did when it happened, see +hit
    :_  this
    %+  turn
      ~(tap by local)
    |=  [=app ours]
    ^-  card
    [%give %fact ~ %hit !>(`hit`[time app kelvin %.y])]
  ==  ::  end of path branches
::
++  on-agent
  |=  [=wire =sign:agent:gall]
  ^-  (quip card _this)
  ?+  wire
    (on-agent:def wire sign)
  ::
      [%~.~ %gossip %gossip ~]
    ?+  -.sign
      ~|([%unexpected-gossip-sign -.sign] !!)
    ::
        %fact
      =*  mark  p.cage.sign
      =*  vase  q.cage.sign
      ?+  mark
        ::
        ::  %gossip-unknown: a rumor from a newer version of us, or one
        ::  that doesn't fit its mark. nothing for us
        ::
        `this
      ::
          %update-docket
        =+  !<(updated-app=app vase)
        ::
        ::  only for apps we show: the rumor can name any ship and desk,
        ::  see +good-app
        ::
        ?.  ?&  (good-app updated-app)
                (~(has by scores) updated-app)
                !(hidden updated-app)
            ==
          `this
        [[(read-docket now.bowl updated-app)]~ this]
      ::
          %hit
        =^  cards  state  (learn bowl state !<(hit vase))
        [cards this]
      ==  ::  end of mark branches
    == ::  end of sign branches
  == ::  end of wire branches
::
++  on-arvo
  |=  [=(pole knot) =sign-arvo]
  ^-  (quip card _this)
  ?+  pole
    (on-arvo:def `wire`pole sign-arvo)
  ::
      [%timers ~]
    ?+  sign-arvo
      (on-arvo:def `wire`pole sign-arvo)
    ::
        [%behn %wake *]
      ::
      ::  every five minutes, check our locally-installed apps and
      ::  who we chat with, each in an event of its own, so that a
      ::  crash in either can't end this loop
      ::
      =?  this  ?=(^ `*`error.sign-arvo)
        ((slog (crip "hits: timer failure {<sign-arvo>}") ~) this)
      :_  this
      %+  weld  (arm-timers now.bowl)
      ^-  (list card)
      :~  [%pass /scan %arvo %b %wait now.bowl]
          [%pass /peers %arvo %b %wait now.bowl]
      ==
    ==
  ::
      [%scan ~]
    ?+  sign-arvo
      (on-arvo:def `wire`pole sign-arvo)
    ::
        [%behn %wake *]
      ?^  `*`error.sign-arvo
        ((slog leaf+"hits: skipping app scan, timer failed" ~) `this)
      ::
      ::  check our locally-installed apps
      ::
      =/  desks
        %-  malt
        %+  skip
          %~  tap  by
          ::  XX tall-form scry causes an error
          ::  .^  rock:tire:clay
          ::      %cx
          ::      /(scot %p our.bowl)
          ::      /
          ::      /(scot %da now.bowl)
          ::      /tire
          ::  ==
          .^(rock:tire:clay %cx /(scot %p our.bowl)//(scot %da now.bowl)/tire)
        |=  [=desk [@tas (set [@tas @ud])]]
        ^-  ?
        (skip-desk desk)
      =/  sources
        %-  malt
        %+  skip
          %~  tap  by
          ::  XX tall-form scry causes an error
          ::      .^  (map desk [ship desk])
          ::          %gx
          ::          /(scot %p our.bowl)
          ::          /hood
          ::          /(scot %da now.bowl)
          ::          /kiln
          ::          /sources
          ::          /noun
          ::      ==
          .^((map desk [ship desk]) %gx /(scot %p our.bowl)/hood/(scot %da now.bowl)/kiln/sources/noun)
        |=  [=desk [ship desk]]
        ^-  ?
        (skip-desk desk)
      ::
      ::  apps on running desks, with the local desk each is on: we may
      ::  have installed it under another name, see +local-desk
      ::
      =/  running=(map app [=desk =kelvin])
        %-  ~(rep by desks)
        |=  $:  [=desk zest=?(%dead %live %held) *]
                result=(map app [=desk =kelvin])
            ==
        ?.  ?=(%live zest)
          result
        ?~  source=(~(get by sources) desk)
          result
        ?~  kelvin=(read-kelvin our.bowl desk now.bowl)
          result
        (~(put by result) u.source [desk u.kelvin])
      ::
      ::  an app keeps the .time we first saw it with, see +ours
      ::
      =/  new-local=(map app ours)
        %-  ~(urn by running)
        |=  [=app =desk =kelvin]
        ^-  ours
        ?^  old=(~(get by local) app)
          [time.u.old kelvin]
        [(fresh now.bowl eny.bowl) kelvin]
      ::
      ::  both empty if there's no difference
      =/  added
        (skip ~(tap by new-local) |=([=app *] (~(has by local) app)))
      =/  removed
        (skip ~(tap by local) |=([=app *] (~(has by new-local) app)))
      =/  hits=(list hit)
        %+  weld
          (turn added |=([=app ours] `hit`[time app kelvin %.y]))
        (turn removed |=([=app ours] `hit`[time app kelvin %.n]))
      ::
      ::  count our own (un)installs, with the new .local, see +learn.
      ::  peers will send them back to us, but gossip drops those as
      ::  hits it has seen
      ::
      =.  local  new-local
      =^  cards  state  (learn-all bowl state hits)
      :_  this
      ;:  weld
        ::
        ::  watch the docket of each app we've installed, and only once
        ::  if we've installed it before
        ::
        %+  weld
          %+  turn
            added
          |=  [=app *]
          ^-  card
          =/  =desk  desk:(~(got by running) app)
          [%pass (docket-wire app) %arvo %c %warp our.bowl desk ~]
        %+  turn
          added
        |=  [=app *]
        ^-  card
        =/  =desk  desk:(~(got by running) app)
        (watch-docket (docket-wire app) our.bowl desk now.bowl)
      ::
        ::  notify via gossip about stuff
        ::  we've (un)installed recently
        (turn hits |=(=hit (invent:gossip %hit !>(hit))))
      ::
        cards
      ==
    ==
  ::
      [%peers ~]
    ?+  sign-arvo
      (on-arvo:def `wire`pole sign-arvo)
    ::
        [%behn %wake *]
      ::
      ::  hand the ships we chat with to gossip, which then hears
      ::  from them as well as from our pals. it ignores a set it
      ::  already has
      ::
      ?^  `*`error.sign-arvo
        ((slog leaf+"hits: skipping chat peers, timer failed" ~) `this)
      :_  this
      =/  peers  (chat-peers our.bowl now.bowl)
      ?~  peers  ~
      [(acquaint:gossip u.peers)]~
    ==
  ::
      [%docket %read =ship =desk ~]
    ?+    sign-arvo
        (on-arvo:def `wire`pole sign-arvo)
    ::
        [%khan %arow *]
      =/  =app  [`@p`(slav %p ship.pole) desk.pole]
      =/  app-score     (~(get by scores) app)
      =/  app-version   (~(get by versions) app)
      =/  app-installs  (~(get by installs) app)
      ::
      ::  we may have forgotten the app while reading its docket, or
      ::  never known it: a docket change in our own copy of an app
      ::  nobody told us about
      ::
      ?:  ?|  (hidden app)
              ?=(~ app-score)
              ?=(~ app-version)
              ?=(~ app-installs)
          ==
        `this
      ::
      ::  %read gives 'nothing' when there's no docket file, and a
      ::  publisher's docket file can be any noun at all
      ::
      =/  docket=(unit docket-0)
        ?.  ?=(%& -.p.sign-arvo)
          ~
        =/  docket  ((soft docket-0) q.q.p.p.sign-arvo)
        ?.  &(?=(^ docket) (sane-docket u.docket))
          ~
        docket
      ::  only what +on-watch would list, so a reload doesn't drop it
      ::
      =/  show=?
        (listed (scry-kelvin our.bowl %base now.bowl) app u.app-version)
      ?~  docket
        %-  %+  slog
              %-  crip
              "hits: failed to read docket file from {<desk.pole>}"
            ~
        :_  this
        ::
        ::  if we fail to read the docket file, we send
        ::  these updates to the frontend. if app already
        ::  exists on the frontend, ui will be updated.
        ::  if app doesn't already exist on the frontend,
        ::  we won't add it until we get a valid docket,
        ::  unless we have one from before
        =/  stored  (~(get by dockets) app)
        ?:  &(show ?=(^ stored))
          :_  ~
          %-  tell-ui
          [%app-update app u.app-score u.app-version u.app-installs u.stored]
        :~  (tell-ui %score-update app u.app-score)
            (tell-ui %version-update app u.app-version)
            (tell-ui %installs-update app u.app-installs)
        ==
      ::
      ::  if we succesfully read the docket file, we add
      ::  the publisher to our 'allies' in %treaty to
      ::  facilitate app downloads from that publisher.
      ::  (%treaty refuses to ally us with ourselves)
      ::
      ::  XX check if we have treaty already to prevent
      ::     'subscribe wire not unique' error
      ::
      :_  this(dockets (~(put by dockets) app u.docket))
      %+  weld
        ?:  =(our.bowl ship.app)  ~
        :_  ~
        :*  %pass
            ~
            %agent
            [our.bowl %treaty]
            %poke
            %ally-update-0
            !>([%add ship.app])
        ==
      ::  XX why not a %docket-update?
      ::     if not here, where should the
      ::     %docket-update be sent? what
      ::     about when we get %update-docket?
      ::
      ?.  show
        ~
      :_  ~
      %-  tell-ui
      [%app-update app u.app-score u.app-version u.app-installs u.docket]
    ==
  ::
      [%docket %update =ship =desk ~]
    ?+    sign-arvo
        (on-arvo:def `wire`pole sign-arvo)
    ::
        [%clay %writ *]
      =/  =app  [`@p`(slav %p ship.pole) desk.pole]
      ::  we're done with the docket if we've uninstalled the app, or if
      ::  clay is
      ::
      =/  here=(unit desk)  (local-desk our.bowl now.bowl app)
      ?:  |(?=(~ here) =(~ p.sign-arvo))
        `this
      :_  this
      :+  %+  invent:gossip
            %update-docket
          !>  ^+  app
          app
        (watch-docket `wire`pole our.bowl u.here now.bowl)
      ::  no need to read what we don't show
      ::
      ?:  (hidden app)  ~
      :_  ~
      :*  %pass
          /docket/read/[ship.pole]/[desk.pole]
          %arvo
          %k
          %fard
          %base
          %read
          %noun
          !>  ^-  [~ care:clay ship desk case path]
          [~ %q our.bowl u.here [%da now.bowl] /desk/docket-0]
      ==
    ==
  ==  ::  end of wire branches
::
++  on-peek   on-peek:def
++  on-fail   on-fail:def
++  on-leave  on-leave:def
--
