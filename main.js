import { default as gulls } from './gulls.js'
import { default as Video    } from './video.js'
import { default as Mouse    } from './mouse.js'

const sg     = await gulls.init(),
      frag   = await gulls.import( 'frag.wgsl' ),
      shader = gulls.constants.vertex + frag

await Video.init()
Mouse.init()

const back = new Float32Array( gulls.width * gulls.height * 4 )
const feedback_t = sg.texture( back )
const mouse_u = sg.uniform( Mouse.values ) 

const render = await sg.render({
  shader,
  data:[
    sg.uniform([ sg.width, sg.height ]),
    mouse_u,
    sg.sampler(),
    feedback_t,
    sg.video( Video.element )
  ],
  copy: feedback_t
})

setInterval(() => {
  console.log( 'Mouse:', Mouse.values )
  sg.device.queue.writeBuffer( mouse_u, 0, new Float32Array( Mouse.values ) )
}, 1000/60)

sg.run( render )