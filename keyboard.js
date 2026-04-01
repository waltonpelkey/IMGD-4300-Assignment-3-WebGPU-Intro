const Keyboard = {
  keys: {},
  key_map: {r: 'KeyR'},

  init() {
    document.addEventListener('keydown', event => {
      Keyboard.keys[event.code] = true
    })

    document.addEventListener('keyup', event => {
      Keyboard.keys[event.code] = false
    })
  },

  get_key_code(key) {
    return Keyboard.key_map[key.toLowerCase()] || key
  },

  isKeyPressed(key) {
    return !!Keyboard.keys[Keyboard.get_key_code(key)]
  }
}

export default Keyboard