const Slider = {
  value: [0],
  init() {
    const slider = document.getElementById('myRange')
    slider.addEventListener('input', (e) => {
      Slider.value[0] = e.target.value / 100
    })
  }
}

export default Slider