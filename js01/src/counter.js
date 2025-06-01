import Observable from './observable'

export function setupCounter(element) {
  const count = new Observable(0)
  count.subscribe((count) => {
    counter = count
    element.innerHTML = `count is ${counter}`
  })
  element.addEventListener('click', () => {
    const current = count.get()
    count.set(current + 1)
  })
  element.innerHTML = `count is 0`
}
