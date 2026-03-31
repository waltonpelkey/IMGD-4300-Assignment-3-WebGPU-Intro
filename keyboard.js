const Keyboard = {
  keys: {},
  
  // Key code mapping for keynames
  keyMap: {
    // Letters
    'a': 'KeyA', 'b': 'KeyB', 'c': 'KeyC', 'd': 'KeyD', 'e': 'KeyE',
    'f': 'KeyF', 'g': 'KeyG', 'h': 'KeyH', 'i': 'KeyI', 'j': 'KeyJ',
    'k': 'KeyK', 'l': 'KeyL', 'm': 'KeyM', 'n': 'KeyN', 'o': 'KeyO',
    'p': 'KeyP', 'q': 'KeyQ', 'r': 'KeyR', 's': 'KeyS', 't': 'KeyT',
    'u': 'KeyU', 'v': 'KeyV', 'w': 'KeyW', 'x': 'KeyX', 'y': 'KeyY',
    'z': 'KeyZ',
    
    // Numbers
    '0': 'Digit0', '1': 'Digit1', '2': 'Digit2', '3': 'Digit3', '4': 'Digit4',
    '5': 'Digit5', '6': 'Digit6', '7': 'Digit7', '8': 'Digit8', '9': 'Digit9',
    
    // Special keys
    'space': 'Space', 'enter': 'Enter', 'escape': 'Escape', 'backspace': 'Backspace',
    'tab': 'Tab', 'shift': 'ShiftLeft', 'ctrl': 'ControlLeft', 'alt': 'AltLeft',
    
    // Arrow keys
    'up': 'ArrowUp', 'down': 'ArrowDown', 'left': 'ArrowLeft', 'right': 'ArrowRight'
  },
  
  init() {
    document.addEventListener('keydown', (event) => {
      Keyboard.keys[event.code] = true
    })
    
    document.addEventListener('keyup', (event) => {
      Keyboard.keys[event.code] = false
    })
  },
  
  getKeyCode(key) {
    return Keyboard.keyMap[key.toLowerCase()] || key
  },
  
  isKeyPressed(key) {
    const keyCode = Keyboard.getKeyCode(key)
    return !!Keyboard.keys[keyCode]
  },
  
  getPressedKeys() {
    return Object.keys(Keyboard.keys).filter(keyCode => Keyboard.keys[keyCode])
  }
}

export default Keyboard