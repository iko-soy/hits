import { useEffect, useMemo, useState } from 'react'

const chartLimit = 40

// apps are told apart by publisher and desk
function appKey(ship, desk) {
  return `${ship}/${desk}`
}

// the rows AppTable can show, so that an app it can't show doesn't take
// a place on the charts
function isShowable(app) {
  const title = app.docket?.title
  return Boolean(app.publisher) && Boolean(title) && title.length <= 30
}

// apps that tie go by name, so that the charts don't depend on the
// order apps came in
function compareKeys(a, b) {
  const keyA = appKey(a.publisher, a.desk)
  const keyB = appKey(b.publisher, b.desk)
  return keyA < keyB ? -1 : keyA > keyB ? 1 : 0
}

function sortAllTimeRankings(rankings) {
  return rankings.sort((a, b) => {
    // by score, then by newest install
    return (b.score - a.score) ||
           (b.installs[0] - a.installs[0]) ||
           compareKeys(a, b)
  })
}

function sortTrendingApps(apps, now) {
  const filteredApps = apps.filter(app => {
    return app.score > 2
  })

  // installs decay from the most recent one, but a peer's clock may be
  // ahead of ours, so not from later than now
  const mostRecentInstall = Math.min(
    now,
    filteredApps.reduce((mostRecentInstall, app) => {
      const mostRecentAppInstall = app.installs[0]
      return Number.isFinite(mostRecentAppInstall) &&
             mostRecentAppInstall > mostRecentInstall
             ? mostRecentAppInstall
             : mostRecentInstall
    }, 0)
  )

  const installLimit = 25
  const trendingScores = new Map(filteredApps.map(app => {
    const score = app.installs.slice(0, installLimit).reduce((totalScore, install) => {
      const time = Number.isFinite(install)
                   ? Math.min(install, mostRecentInstall)
                   : mostRecentInstall
      const timeDiff = mostRecentInstall - time
      // TODO adjust score decay rate based on testing
      // score decays based on how many 24-hour periods
      // are in the timeDiff
      return totalScore + Math.exp(-timeDiff / 86400000)
    }, 0)

    return [app, score]
  }))

  return filteredApps.sort((a, b) => {
    return (trendingScores.get(b) - trendingScores.get(a)) ||
           compareKeys(a, b)
  })
}

export default function useHitsState() {
  // every app we can show, by appKey. the charts are worked out from
  // all of them, so an app can move onto a chart when another leaves
  const [apps, setApps] = useState({})

  // TRENDING decays from now when an install is ahead of our clock, so
  // work it out again as time passes
  const [now, setNow] = useState(Date.now())
  useEffect(() => {
    const timer = setInterval(() => setNow(Date.now()), 60000)
    return () => clearInterval(timer)
  }, [])

  const allTimeRankings = useMemo(() => {
    const showable = Object.values(apps).filter(isShowable)
    return sortAllTimeRankings(showable).slice(0, chartLimit)
  }, [apps])

  const trendingApps = useMemo(() => {
    const showable = Object.values(apps).filter(isShowable)
    return sortTrendingApps(showable, now).slice(0, chartLimit)
  }, [apps, now])

  // forget every app, before the agent sends them all again
  function resetApps() {
    setApps({})
  }

  // change an app we already show; the others only come with an app-update
  function updateApp(uiUpdate, change) {
    setApps(prevApps => {
      const key = appKey(uiUpdate.ship, uiUpdate.desk)
      if (!prevApps[key]) {
        return prevApps
      }

      return { ...prevApps, [key]: { ...prevApps[key], ...change } }
    })
  }

  function receiveUiUpdate(uiUpdate) {
    switch (uiUpdate.updateTag) {
      case 'score-update':
        console.log('score-update for ', uiUpdate.desk)

        // the last known install was removed
        if (uiUpdate.score <= 0) {
          setApps(prevApps => {
            const { [appKey(uiUpdate.ship, uiUpdate.desk)]: _, ...rest } = prevApps
            return rest
          })
          break
        }

        updateApp(uiUpdate, { score: uiUpdate.score })
        break

      case 'version-update':
        console.log('version-update for ', uiUpdate.desk)
        updateApp(uiUpdate, { version: uiUpdate.version })
        break

      case 'installs-update':
        console.log('installs-update for ', uiUpdate.desk)
        updateApp(uiUpdate, { installs: uiUpdate.installs })
        break

      case 'docket-update':
        console.log('docket-update for ', uiUpdate.desk)
        updateApp(uiUpdate, { docket: uiUpdate.docket })
        break

      case 'app-update':
        setApps(prevApps => ({
          ...prevApps,
          [appKey(uiUpdate.ship, uiUpdate.desk)]: {
            desk: uiUpdate.desk,
            publisher: uiUpdate.ship,
            score: uiUpdate.score,
            version: uiUpdate.version,
            installs: uiUpdate.installs,
            docket: uiUpdate.docket,
          }
        }))
        break

      default:
        console.log('Unknown uiUpdate: ', uiUpdate)
    }
  }

  return { allTimeRankings, receiveUiUpdate, resetApps, trendingApps }
}
