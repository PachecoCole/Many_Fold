import * as Comlink from 'comlink'
import 'src/comlink_event_handler'

let progressBar: HTMLDivElement | null
let progressLabel: HTMLSpanElement | null

const load = async (preview): void => {
  await preview.load(
    Comlink.proxy(onLoad),
    Comlink.proxy(onLoadProgress),
    Comlink.proxy(onLoadError)
  )
}

const onLoadProgress = (percentage: number): void => {
  if ((progressBar == null) || (progressLabel == null)) { return }
  if (percentage === 100) {
    progressLabel.textContent = 'Reticulating splines...'
  } else {
    progressLabel.textContent = `${percentage}%`
  }
  progressBar.style.width = `${percentage}%`
  progressBar.ariaValueNow = percentage
}

const onLoad = (): void => {
  progressBar?.parentElement?.remove()
  progressBar = null
  progressLabel = null
}

const onLoadError = (): void => {
  if ((progressBar == null) || (progressLabel == null)) { return }
  progressBar?.classList.add('bg-danger')
  progressBar.style.width = progressBar.ariaValueNow = '100%'
  progressLabel.textContent = window.i18n.t('renderer.errors.load')
}

document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('[data-preview]').forEach(async (canvas: HTMLCanvasElement) => {
    progressBar = canvas.parentElement?.getElementsByClassName('progress-bar')[0] as HTMLDivElement
    progressLabel = canvas.parentElement?.getElementsByClassName('progress-label')[0] as HTMLSpanElement
    // Create offscreen renderer worker
    const OffscreenRenderer = Comlink.wrap(
      new Worker('/assets/offscreen_renderer.js', { type: 'module' })
    )
    const offscreenCanvas = canvas.transferControlToOffscreen()
    const preview = await new OffscreenRenderer(
      Comlink.transfer(offscreenCanvas, [offscreenCanvas]),
      {
        ...canvas.dataset
      },
      {
        width: canvas.clientWidth,
        height: canvas.clientHeight,
        pixelRatio: window.devicePixelRatio
      }
    )
    // Send resize events
    window.addEventListener('resize', () => (preview.resize(canvas.clientWidth, canvas.clientHeight)))
    // Handle interaction events
    const eventHandlers = [
      'pointerdown',
      'pointermove',
      'pointerup',
      'wheel',
      'keydown',
      'keyup'
    ]
    eventHandlers.forEach((eventName) => {
      canvas.addEventListener(eventName, preview.handleEvent.bind(preview))
    })
    // Autoload
    if (canvas.dataset.autoLoad === 'true') {
      load(preview)
    }
  })
})
