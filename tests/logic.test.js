// Run with: node --test
const test = require("node:test")
const assert = require("node:assert")
const L = require("../plugin/NotificationLogic.js")

test("timeLabel names the day the way the notification center shows it", () => {
  const now = new Date(2026, 9, 29, 16, 30).getTime()
  const at = (...a) => new Date(...a).getTime()
  assert.strictEqual(L.timeLabel(at(2026, 9, 29, 9, 5), now), "09:05")
  assert.strictEqual(L.timeLabel(at(2026, 9, 28, 23, 59), now), "Yesterday 23:59")
  assert.strictEqual(L.timeLabel(at(2026, 9, 26, 8, 0), now), "Mon 08:00")
  assert.strictEqual(L.timeLabel(at(2026, 9, 3, 14, 5), now), "3 Oct 14:05")
  // A clock running ahead of the sender's shows the time, not a day.
  assert.strictEqual(L.timeLabel(at(2026, 9, 29, 17, 0), now), "17:00")
})

test("historyRows keeps the newest 50 when given the BOSS history limit", () => {
  const raw = Array.from({ length: 60 }, (_, i) =>
    JSON.stringify({ id: i, originalId: i, app: "a", summary: "n" + i, body: "", urgency: 1, timestamp: 1000 + i })
  ).join("\n")
  const rows = L.historyRows(raw, [], 1, 50)
  assert.strictEqual(rows.length, 50)
  assert.strictEqual(rows[0].summary, "n59")
  assert.strictEqual(rows[49].summary, "n10")
})
