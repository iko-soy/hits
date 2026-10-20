/-  *hits
::  +show-website: a docket's website, if the frontend may link to it
::
::    eyre renders our facts without virtualizing, and +de-purl takes
::    long to parse a long cord
::
=>  |%
    ++  show-website
      |=  website=cord
      ^-  cord
      ?:  (gth (met 3 website) 256)  ''
      ?~((de-purl:html website) '' website)
    --
|_  upd=ui-update
++  grab
  |%
  ++  noun  ui-update
  --
++  grow
  |%
  ++  noun  upd
  ++  json
    ?-  -.upd
        %score-update
      %-  pairs:enjs:format
      :~  ['updateTag' [%s 'score-update']]
          ['ship' [%s (scot %p ship.app.upd)]]
          ['desk' [%s (scot %tas desk.app.upd)]]
          ['score' (numb:enjs:format score.upd)]
      ==
    ::
        %version-update
      %-  pairs:enjs:format
      :~  ['updateTag' [%s 'version-update']]
          ['ship' [%s (scot %p ship.app.upd)]]
          ['desk' [%s (scot %tas desk.app.upd)]]
          ['version' (numb:enjs:format kelvin.upd)]
      ==
    ::
        %installs-update
      %-  pairs:enjs:format
      :~  ['updateTag' [%s 'installs-update']]
          ['ship' [%s (scot %p ship.app.upd)]]
          ['desk' [%s (scot %tas desk.app.upd)]]
          :-  'installs'
          :-  %a
          ::  the frontend only looks at the 25 most recent
          ::
          %+  turn
            (scag 25 installs.upd)
          ::  +time:enjs crashes on times before 1970, and eyre doesn't
          ::  virtualize mark conversion
          ::
          |=(=time (time:enjs:format (max ~1970.1.1 time)))
      ==
    ::
        %docket-update
      =,  docket.upd
      %-  pairs:enjs:format
      :~  ['updateTag' [%s 'docket-update']]
          ['ship' [%s (scot %p ship.app.upd)]]
          ['desk' [%s (scot %tas desk.app.upd)]]
          :-  'docket'
          %-  pairs:enjs:format
          :~  ['title' [%s title]]
              ['info' [%s info]]
              ['color' [%s (scot %ux color)]]
              ['image' [%s ?~(image '' (need image))]]
              ['website' [%s (show-website website)]]
              ['license' [%s license]]
              :-  'version'
              :-  %s
              (crip "{<major.version>}.{<minor.version>}.{<patch.version>}")
              :-  'href'
              =/  href=^href  href
              %+  frond:enjs:format
                -.href
              ?-  -.href
                  %site
                [%s (spat path.href)]
              ::
                  %glob
                %-  pairs:enjs:format
                :~  ['base' [%s base.href]]
                    :-  'glob-reference'
                    %-  pairs:enjs:format
                    :~  ['hash' [%s (scot %uv hash.glob-reference.href)]]
                        :-  'location'
                        %+  frond:enjs:format
                          -.location.glob-reference.href
                        ?-  -.location.glob-reference.href
                            %http
                          [%s url.location.glob-reference.href]
                        ::
                            %ames
                          [%s (scot %p ship.location.glob-reference.href)]
                        ==
                    ==
                ==
              ==
          ==
      ==
    ::
        %app-update
      %-  pairs:enjs:format
      :~  ['updateTag' [%s 'app-update']]
          ['ship' [%s (scot %p ship.app.upd)]]
          ['desk' [%s (scot %tas desk.app.upd)]]
          ['score' (numb:enjs:format score.upd)]
          ['version' (numb:enjs:format kelvin.upd)]
          :-  'installs'
          :-  %a
          %+  turn
            (scag 25 installs.upd)
          |=  =time
          (time:enjs:format (max ~1970.1.1 time))
          =,  docket.upd
          :-  'docket'
          %-  pairs:enjs:format
          :~  ['title' [%s title]]
              ['info' [%s info]]
              ['color' [%s (scot %ux color)]]
              ['image' [%s ?~(image '' (need image))]]
              ['website' [%s (show-website website)]]
              ['license' [%s license]]
              :-  'version'
              :-  %s
              (crip "{<major.version>}.{<minor.version>}.{<patch.version>}")
              :-  'href'
              =/  href=^href  href
              %+  frond:enjs:format
                -.href
              ?-  -.href
                  %site
                [%s (spat path.href)]
              ::
                  %glob
                %-  pairs:enjs:format
                :~  ['base' [%s base.href]]
                    :-  'glob-reference'
                    %-  pairs:enjs:format
                    :~  ['hash' [%s (scot %uv hash.glob-reference.href)]]
                        :-  'location'
                        %+  frond:enjs:format
                          -.location.glob-reference.href
                        ?-  -.location.glob-reference.href
                            %http
                          [%s url.location.glob-reference.href]
                        ::
                            %ames
                          [%s (scot %p ship.location.glob-reference.href)]
                        ==
                    ==
                ==
              ==
          ==
      ==
    ==
  --
++  grad  %noun
--
