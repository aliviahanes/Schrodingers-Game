# Schrodinger Documentation

## Table of Contents
- [Dialogue System](#dialogue-system)

---

## Dialogue System

The Dialogue System handles all NPC interactions, branching choices, and narrative triggers.

### Data Structure
Dialogue conversations are stored as-is in JSON. Below is the standard schema for each kind of message:

```json
{
	"id": "(_unique conversation id string_)",
	"messages": [
		{
			"message_id": "(_unique message id string_)",
			"participant1": "(_speaker id string or placeholder)",
			"participant1_mood": 0,
			"participant2": "(_speaker id string or placeholder)",
			"participant2_mood": 0,
			"speaker": "(_speaker id string or placeholder_)",
			"content": "(_content string_)",
			"ending": false,
			"next": "(_message id string_)"
		},
		{
			"message_id": "(_unique message id string_)",
			"participant1": "(_speaker id string or placeholder)",
			"participant1_mood": 0,
			"participant2": "(_speaker id string or placeholder)",
			"participant2_mood": 0,
			"speaker": "(_speaker id string or placeholder_)",
			"content": "(_content string_)",
			"ending": false,
			"responses": [
				{
					"redirect": "(_message id string_)",
					"content": "(_content_)"
				}
			]
		},
		{
			"message_id": "(_unique message id string_)",
			"participant1": "(_speaker id string or placeholder)",
			"participant1_mood": 0,
			"participant2": "(_speaker id string or placeholder)",
			"participant2_mood": 0,
			"speaker": "(_speaker id string or placeholder_)",
			"content": "(_content string_)",
			"ending": true
		}
	]
}

```
