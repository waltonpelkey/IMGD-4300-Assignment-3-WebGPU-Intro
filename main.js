import { default as gulls } from './gulls.js'
import { default as Video } from './video.js'
import { default as Keyboard } from './keyboard.js'
import { default as Slider } from './slider.js'
import { default as Audio } from './audio.js'

// start gulls
const sg = await gulls.init()

// load the fragment shader file
const frag = await gulls.import('frag.wgsl')

// put the vertex shader and fragment shader together
const shader = gulls.constants.vertex + frag

// the most ripples we want at once
const max_ripples = 32

// how many numbers each ripple uses
const ripple_values_per_ripple = 4

// how long one ripple stays alive
const ripple_lifetime = 3.0

// how much to smooth the audio values
const audio_smoothing = 0.08

// turn on the js input stuff
await Video.init()
Keyboard.init()
Slider.init()
await Audio.start()

// shader data
const slider_u = sg.uniform([Slider.value[0], 0, 0, 0])
const audio_u = sg.uniform([0, 0, 0, 0])
const time_buffer = new Float32Array([0])
const time_u = sg.uniform(time_buffer)
const video_sampler = sg.sampler()
const smooth_audio_values = [0, 0, 0, 0]
const ripple_data = new Float32Array(max_ripples * ripple_values_per_ripple)

// start all ripples as already expired
for (let i = 0; i < max_ripples; i++) {
  ripple_data[i * ripple_values_per_ripple + 2] = -1
}

// make the gpu buffer for the ripples
const ripple_buffer = sg.buffer(ripple_data, 'ripple buffer')

// rain and ripple state
let ripple_write_index = 0
let rain_mode = false
let previous_r_key = false
let last_rain_time = 0

// wake the audio back up after a user action
function resume_audio_context() {
  if (Audio.ctx && Audio.ctx.state === 'suspended') {
    Audio.ctx.resume()
  }
}

// send the ripple data to the gpu
function write_ripples() {
  sg.device.queue.writeBuffer(ripple_buffer.buffer, 0, ripple_data)
}

// add one ripple to the ripple list
function add_ripple(x, y, now, ripple_size = 1) {
  // no slot picked yet
  let slot = -1

  // look for an old ripple we can reuse
  for (let i = 0; i < max_ripples; i++) {
    // start of this ripple in the array
    const base = i * ripple_values_per_ripple

    // reuse this slot if the ripple is old enough
    if (now - ripple_data[base + 2] > ripple_lifetime) {
      slot = i
      break
    }
  }

  // if no old slot was free overwrite the next one
  if (slot === -1) {
    slot = ripple_write_index
    ripple_write_index = (ripple_write_index + 1) % max_ripples
  }

  // start of the chosen ripple slot
  const base = slot * ripple_values_per_ripple

  // save the ripple data
  ripple_data[base + 0] = x
  ripple_data[base + 1] = y
  ripple_data[base + 2] = now
  ripple_data[base + 3] = ripple_size

  // send the new ripple data to the gpu
  write_ripples()
}

// build the render pass
const render = await sg.render({
  shader,
  data: [
    // send these values into the shader
    sg.uniform([sg.width, sg.height]),
    slider_u,
    audio_u,
    time_u,
    ripple_buffer,
    video_sampler,
    sg.video(Video.element)
  ]
})

// update all live values many times per second
setInterval(() => {
  // smooth the audio values
  smooth_audio_values[0] += ((Audio.low || 0) - smooth_audio_values[0]) * audio_smoothing
  smooth_audio_values[1] += ((Audio.mid || 0) - smooth_audio_values[1]) * audio_smoothing
  smooth_audio_values[2] += ((Audio.high || 0) - smooth_audio_values[2]) * audio_smoothing

  // send live values to the shader
  sg.device.queue.writeBuffer(audio_u, 0, new Float32Array([
    smooth_audio_values[0],
    smooth_audio_values[1],
    smooth_audio_values[2],
    0
  ]))
  sg.device.queue.writeBuffer(slider_u, 0, new Float32Array([Slider.value[0], 0, 0, 0]))
  time_buffer[0] = performance.now() * 0.001
  sg.device.queue.writeBuffer(time_u, 0, time_buffer)

  // check the rain toggle
  const r_key = Keyboard.isKeyPressed('r')
  if (r_key && !previous_r_key) {
    rain_mode = !rain_mode
  }
  previous_r_key = r_key

  // add random rain ripples while rain mode is on
  if (rain_mode && time_buffer[0] - last_rain_time > 0.12) {
    add_ripple(Math.random(), Math.random(), time_buffer[0], 0.45)
    last_rain_time = time_buffer[0]
  }
}, 1000 / 60)

// start drawing
sg.run(render)

// wake audio up after user input
document.addEventListener('pointerdown', resume_audio_context)
document.addEventListener('keydown', resume_audio_context)

// add a ripple when the canvas is clicked
sg.canvas.addEventListener('click', event => {
  // get the click info
  const rect = sg.canvas.getBoundingClientRect()
  const now = performance.now() * 0.001

  // add a full size ripple at the click spot
  add_ripple(
    (event.clientX - rect.left) / rect.width,
    (event.clientY - rect.top) / rect.height,
    now,
    1
  )
})
