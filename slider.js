const Slider = {
  value: [0.5, 0, 0, 0],
  init() {
    const slider = document.getElementById('myRange')
    if (!slider) return

    // Start value as 0..1
    Slider.value[0] = slider.value / 100

    slider.addEventListener('input', (e) => {
      Slider.value[0] = e.target.value / 100
    })
  }
}

export default Slider