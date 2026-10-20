import { useState, useEffect } from 'react'
import { scryCharges } from '../api/scries.js'

export default function useDesksState() {
  const [loadingDesks, setLoadingDesks] = useState([])
  const [installedDesks, setInstalledDesks] = useState([])

  async function refreshDesks() {
    const initial = await scryCharges()
    setInstalledDesks(Object.keys(initial))
    // installs that finished while we weren't listening
    setLoadingDesks(prevDesks => {
      return prevDesks.filter(loadingDesk => {
        return initial[loadingDesk] && 'install' in initial[loadingDesk].chad
      })
    })
  }

  useEffect(() => {
    refreshDesks()
  }, [])

  useEffect(() => {
    console.log('new installedDesks: ', installedDesks)
  }, [installedDesks])

  useEffect(() => {
    console.log('new loadingDesks: ', loadingDesks)
  }, [loadingDesks])

  function receiveDesksUpdate(chargesUpdate) {
    if ('add-charge' in chargesUpdate) {
      const { charge, desk } = chargesUpdate['add-charge']
      const chadTag = Object.keys(charge.chad)[0]

      switch (chadTag) {
        case 'glob':
          setInstalledDesks(prevDesks => {
            return prevDesks.includes(desk)
                   ? prevDesks
                   : [...prevDesks, desk]
          })
          setLoadingDesks(prevDesks => {
            return prevDesks.filter(loadingDesk => {
              return loadingDesk !== desk
            })
          })
          break
        case 'site':
          setInstalledDesks(prevDesks => {
            return prevDesks.includes(desk)
                   ? prevDesks
                   : [...prevDesks, desk]
          })
          setLoadingDesks(prevDesks => {
            return prevDesks.filter(loadingDesk => {
              return loadingDesk !== desk
            })
          })
          break
        case 'install':
          setLoadingDesks(prevDesks => {
            return prevDesks.includes(desk)
                   ? prevDesks
                   : [...prevDesks, desk]
          })
          break
        // TODO start loading spinner but with 'OPEN'
        //      color scheme
        // case 'suspend':
        //   return
        //   break
        case 'hung':
          setLoadingDesks(prevDesks => {
            return prevDesks.filter(loadingDesk => {
              return loadingDesk !== desk
            })
          })
          break
        default:
          return;
      }
    }

    // if ('del-charge' in chargesUpdate) {
    //   // TODO add del-charge logic?
    //   return;
    // }
  }

  return {installedDesks, loadingDesks, receiveDesksUpdate, refreshDesks}
}
