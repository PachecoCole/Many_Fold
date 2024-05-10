import { EventDispatcher } from 'three'

export class CanvasProxy extends EventDispatcher {
  style = { touchAction: '' }
  clientWidth: number = 100
  clientHeight: number = 100
  realCanvas: HTMLCanvasElement

  ownerDocument = this

  constructor (canvas: HTMLCanvasElement) {
    super()
    this.realCanvas = canvas
  }

  getBoundingClientRect (): DOMRect {
    return {
      left: 0,
      top: 0,
      width: this.clientWidth,
      height: this.clientHeight,
      right: this.clientWidth,
      bottom: this.clientHeight
    }
  }

  resize (width, height): void {
    this.clientWidth = width
    this.clientHeight = height
    this.realCanvas.width = width
    this.realCanvas.height = height
  }

  handleEvent (event: Event): void {
    event.preventDefault = function () { }
    this.dispatchEvent(event as never)
  }

  // Pretend we can handle capture events
  getRootNode (): CanvasProxy {
    return this
  }

  setPointerCapture (): void {}
  releasePointerCapture (): void {}
}
