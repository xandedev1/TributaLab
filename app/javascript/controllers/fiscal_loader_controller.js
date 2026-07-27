import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "circle", "percentage", "label"]

  connect() {
    this.progress = 0
    this.onSubmitStart = () => this.start()
    this.onBeforeVisit = () => this.start()
    this.onBeforeRender = () => this.advanceTo(96, "Montando indicadores")

    document.addEventListener("turbo:submit-start", this.onSubmitStart)
    document.addEventListener("turbo:before-visit", this.onBeforeVisit)
    document.addEventListener("turbo:before-render", this.onBeforeRender)

    if (sessionStorage.getItem("fiscalLoaderActive")) {
      this.show()
      this.advanceTo(96, "Finalizando painel")
      window.setTimeout(() => this.complete(), 120)
    }
  }

  disconnect() {
    document.removeEventListener("turbo:submit-start", this.onSubmitStart)
    document.removeEventListener("turbo:before-visit", this.onBeforeVisit)
    document.removeEventListener("turbo:before-render", this.onBeforeRender)
    window.clearInterval(this.timer)
  }

  start() {
    if (!this.overlayTarget.hidden) return

    sessionStorage.setItem("fiscalLoaderActive", "true")
    this.show()
    this.advanceTo(8, "Lendo filtros selecionados")
    this.timer = window.setInterval(() => {
      const next = Math.min(92, this.progress + Math.max(1, Math.round((92 - this.progress) * 0.12)))
      const label = next < 55 ? "Cruzando emissão e competências" : "Calculando retenções"
      this.advanceTo(next, label)
    }, 110)
  }

  complete() {
    window.clearInterval(this.timer)
    this.advanceTo(100, "Leitura concluída")
    sessionStorage.removeItem("fiscalLoaderActive")
    window.setTimeout(() => {
      this.overlayTarget.hidden = true
      this.overlayTarget.setAttribute("aria-hidden", "true")
    }, 360)
  }

  show() {
    this.overlayTarget.hidden = false
    this.overlayTarget.setAttribute("aria-hidden", "false")
  }

  advanceTo(value, label) {
    this.progress = Math.max(this.progress, value)
    this.percentageTarget.textContent = `${this.progress}%`
    this.labelTarget.textContent = label
    this.circleTarget.style.strokeDashoffset = `${301.6 * (1 - this.progress / 100)}`
  }
}