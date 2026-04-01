const Slider = {
  value: [0.5, 0, 0, 0],
  init() {
    const slider = document.getElementById('myRange')
    if (!slider) return

    Slider.value[0] = slider.value / 100
    slider.addEventListener('input', event => {
      Slider.value[0] = event.target.value / 100
    })
  }
}

export default Slider