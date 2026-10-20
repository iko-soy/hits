import Urbit from '@urbit/http-api'

// eyre ends a subscription when its channel falls behind or is reaped,
// and the agent ends ours when it's upgraded, so subscribe again after
// a quit, and keep trying until it works. onRestart runs before each
// try, to drop what the new subscription will tell us again, and
// onRestarted once it's in place, to catch up on what it won't
function subscribeToUrbit(app, path, event, { onRestart, onRestarted }) {
  const api = new Urbit('', '', app)

  function subscribe() {
    return api.subscribe({
      app: app,
      path: path,
      ship: window.ship,
      err: () => {console.error(`Failed to subscribe to ${path}`)},
      event: event,
      quit: () => {
        console.log(`Kicked from ${path}, subscribing again`)
        restart(1000)
      }
    })
  }

  function restart(delay) {
    setTimeout(async () => {
      try {
        if (onRestart) {
          onRestart()
        }
        await subscribe()
      } catch (e) {
        console.error(`Failed to subscribe to ${path}, trying again`, e)
        restart(Math.min(delay * 2, 30000))
        return
      }
      if (onRestarted) {
        onRestarted()
      }
    }, delay)
  }

  return subscribe().catch(e => {
    console.error(`Failed to subscribe to ${path}, trying again`, e)
    restart(1000)
  })
}

export async function subscribeToCharges(event, onRestarted) {
  return await subscribeToUrbit('docket', '/charges', event, { onRestarted })
}

export async function subscribeToUiUpdates(event, onRestart) {
  return await subscribeToUrbit('hits', '/ui-updates', event, { onRestart })
}
