// app/javascript/controllers/transaction_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["transactionType", "executionDateField"]

  connect() {
    this.toggleExecutionDate()
  }

  toggleExecutionDate() {
    if (this.transactionTypeTarget.value === "scheduled") {
      this.executionDateFieldTarget.style.display = "block"
    } else {
      this.executionDateFieldTarget.style.display = "none"
    }
  }

  change() {
    this.toggleExecutionDate()
  }
}