import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["operationSelect", "operationPanel", "contextPanel"]

  connect() {
    this.update()
  }

  update() {
    const selectedOperation = this.operationSelectTarget.value

    this.operationPanelTargets.forEach((panel) => {
      const visible = panel.dataset.operationCode === selectedOperation
      panel.classList.toggle("hidden", !visible)

      panel.querySelectorAll("input, select, textarea").forEach((field) => {
        field.disabled = !visible
      })
    })

    this.contextPanelTargets.forEach((panel) => {
      panel.classList.toggle("hidden", panel.dataset.operationCode !== selectedOperation)
    })
  }
}