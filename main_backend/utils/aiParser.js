/**
 * aiParser.js
 * Utility functions for detecting @classAI triggers and extracting
 * query content and entity mentions (student/teacher IDs) from messages.
 */

/**
 * Returns true if the message contains the @classAI trigger.
 * @param {string} message
 * @returns {boolean}
 */
function isAITriggered(message) {
  return /\@classai/i.test(message);
}

/**
 * Strips @classAI and any entity mentions to get the clean question.
 * @param {string} message
 * @returns {string}
 */
function extractQuery(message) {
  return message
    .replace(/@classai/gi, '')
    .replace(/@STD\d+/gi, '')
    .replace(/@TCH\d+/gi, '')
    .trim();
}

/**
 * Extracts the first @STUxxx or @STDxxx student mention from a message.
 * Returns the raw ID string (e.g. "STU001") or null.
 * @param {string} message
 * @returns {string|null}
 */
function extractStudentId(message) {
  const match = message.match(/@(STU\d+|STD\d+)/i);
  return match ? match[1].toUpperCase() : null;
}

/**
 * Extracts the first @TCHxxx teacher mention from a message.
 * Returns the raw ID string (e.g. "TCH001") or null.
 * @param {string} message
 * @returns {string|null}
 */
function extractTeacherId(message) {
  const match = message.match(/@(TCH\d+)/i);
  return match ? match[1].toUpperCase() : null;
}

module.exports = { isAITriggered, extractQuery, extractStudentId, extractTeacherId };
