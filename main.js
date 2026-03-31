import { default as gulls } from './gulls.js'
import { default as Video    } from './video.js'
import { default as Mouse    } from './mouse.js'
import { default as Keyboard } from './keyboard.js'
import { default as Slider   } from './slider.js'

const sg     = await gulls.init(),
      frag   = await gulls.import( 'frag.wgsl' ),
      shader = gulls.constants.vertex + frag

await Video.init()
Mouse.init()
Keyboard.init()
Slider.init()

const back = new Float32Array( gulls.width * gulls.height * 4 )
const feedback_t = sg.texture( back )
const mouse_u = sg.uniform( Mouse.values ) 
const keyboard_u = sg.uniform([0, 0, 0, 0]) // W, A, S, D keys
const slider_u = sg.uniform([Slider.value[0], 0, 0, 0])

const render = await sg.render({
  shader,
  data:[
    sg.uniform([ sg.width, sg.height ]),
    mouse_u,
    sg.sampler(),
    feedback_t,
    keyboard_u,
    slider_u,
    sg.video( Video.element )
  ],
  copy: feedback_t
})

setInterval(() => {
  sg.device.queue.writeBuffer( mouse_u, 0, new Float32Array( Mouse.values ) )
  // Update keyboard uniform with WASD key states
  const keyboardValues = [
    Keyboard.isKeyPressed('w') ? 1 : 0,  // W key
    Keyboard.isKeyPressed('a') ? 1 : 0,  // A key  
    Keyboard.isKeyPressed('s') ? 1 : 0,  // S key
    Keyboard.isKeyPressed('d') ? 1 : 0   // D key
  ]
  sg.device.queue.writeBuffer( keyboard_u, 0, new Float32Array( keyboardValues ) )

  // Update slider uniform
  const sliderValue = Math.min(1, Math.max(0, Number(Slider.value[0] || 0)))
  const sliderValues = [sliderValue, 0, 0, 0]
  sg.device.queue.writeBuffer( slider_u, 0, new Float32Array( sliderValues ) )

  // Debug logging
  console.log('Keyboard state', keyboardValues, 'Slider', sliderValue)
}, 1000/60)

sg.run( render )