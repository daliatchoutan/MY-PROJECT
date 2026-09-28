/**
 * NOVARA IoT Two-Way Command Queue
 * Handles queued actuator control commands sent from Flutter Web / Mobile to ESP32 devices
 * operating behind local NAT / Wi-Fi networks.
 */

const { v4: uuidv4 } = require('crypto').randomUUID ? { v4: require('crypto').randomUUID } : { v4: () => Math.random().toString(36).substring(2, 15) };

// Map of deviceSerial (or deviceId) -> Array of pending commands
const commandQueue = new Map();

/**
 * Enqueue a control command for an IoT device
 * @param {string} deviceKey - deviceSerial or deviceId
 * @param {string} action - e.g. 'PUMP_ON', 'PUMP_OFF', 'FEEDER_ON', 'HEATER_ON', etc.
 * @param {object} params - optional extra parameters (e.g. duration, angle)
 */
function enqueueCommand(deviceKey, action, params = {}) {
  if (!deviceKey || !action) return null;
  const key = String(deviceKey).trim().toUpperCase();

  if (!commandQueue.has(key)) {
    commandQueue.set(key, []);
  }

  const command = {
    id: `cmd-${Date.now()}-${Math.floor(Math.random() * 1000)}`,
    action: String(action).toUpperCase(),
    params: params || {},
    createdAt: new Date().toISOString()
  };

  commandQueue.get(key).push(command);
  console.log(`📡 [IoT Command Enqueued] Device: '${key}' -> Action: '${command.action}' (Queue length: ${commandQueue.get(key).length})`);
  return command;
}

/**
 * Retrieve and optionally consume (dequeue) pending commands for an IoT device
 * @param {string} deviceKey - deviceSerial or deviceId
 * @param {boolean} consume - if true, clears the queue
 */
function getPendingCommands(deviceKey, consume = true) {
  if (!deviceKey) return [];
  const key = String(deviceKey).trim().toUpperCase();

  const commands = commandQueue.get(key) || [];
  if (consume && commands.length > 0) {
    commandQueue.set(key, []);
    console.log(`📥 [IoT Commands Dequeued] Device: '${key}' consumed ${commands.length} command(s)`);
  }
  return commands;
}

/**
 * Check count of pending commands without consuming
 * @param {string} deviceKey
 */
function peekPendingCommands(deviceKey) {
  if (!deviceKey) return [];
  const key = String(deviceKey).trim().toUpperCase();
  return commandQueue.get(key) || [];
}

/**
 * Clear pending commands for a device
 * @param {string} deviceKey
 */
function clearCommands(deviceKey) {
  if (!deviceKey) return;
  const key = String(deviceKey).trim().toUpperCase();
  commandQueue.delete(key);
}

module.exports = {
  enqueueCommand,
  getPendingCommands,
  peekPendingCommands,
  clearCommands
};
